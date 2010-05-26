// -- Copyright (C) 2009 Marcos Ortíz Valmaseda, Pavel Stehule
// --
// -- All rights reserved.
// --
// -- Lincensed using BSD License.
// -- For information about license see COPYING file in the root directory of current nominal package
// 
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------

#include "postgres.h"
#include "stdio.h"
#include "wchar.h"

#include "catalog/pg_type.h"
#include "lib/stringinfo.h"
#include "mb/pg_wchar.h"
#include "parser/parse_coerce.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/pg_locale.h"

PG_MODULE_MAGIC;

#define CHECK_SEQ_SEARCH(_l, _s) \
do { \
	if ((_l) < 0) { \
		ereport(ERROR, \
				(errcode(ERRCODE_INVALID_DATETIME_FORMAT), \
				 errmsg("invalid value for %s", (_s)))); \
	} \
} while (0)

#define CHECK_PAD(symbol, pad_value)	\
do { \
	if (pdesc->flags & pad_value)		\
		ereport(ERROR,  	\
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE), \
				 errmsg("broken sprintf format"),          \
				 errdetail("Format string is '%s'.", TextDatumGetCString(fmt)), 	   \
				 errhint("Symbol '%c' can be used only one time.", symbol))); \
	pdesc->flags |= pad_value; \
} while(0);

/*
 * string functions
 */
Datum	pst_sprintf(PG_FUNCTION_ARGS);
Datum	pst_sprintf_nv(PG_FUNCTION_ARGS);
Datum	pst_format(PG_FUNCTION_ARGS);
Datum	pst_format_nv(PG_FUNCTION_ARGS);
Datum	pst_concat(PG_FUNCTION_ARGS);
Datum	pst_concat_ws(PG_FUNCTION_ARGS);
Datum	pst_concat_js(PG_FUNCTION_ARGS);
Datum	pst_concat_sql(PG_FUNCTION_ARGS);
Datum	pst_left(PG_FUNCTION_ARGS);
Datum	pst_right(PG_FUNCTION_ARGS);
Datum	pst_left(PG_FUNCTION_ARGS);
Datum	pst_rvrs(PG_FUNCTION_ARGS);
Datum	pst_chars_to_array(PG_FUNCTION_ARGS);

/*
 * date functions
 */
Datum	pst_next_day(PG_FUNCTION_ARGS);
Datum	pst_last_day(PG_FUNCTION_ARGS);

/*
 * V1 registrations
 */
PG_FUNCTION_INFO_V1(pst_sprintf);
PG_FUNCTION_INFO_V1(pst_sprintf_nv);
PG_FUNCTION_INFO_V1(pst_format);
PG_FUNCTION_INFO_V1(pst_format_nv);
PG_FUNCTION_INFO_V1(pst_concat);
PG_FUNCTION_INFO_V1(pst_concat_ws);
PG_FUNCTION_INFO_V1(pst_concat_js);
PG_FUNCTION_INFO_V1(pst_concat_sql);
PG_FUNCTION_INFO_V1(pst_rvrs);
PG_FUNCTION_INFO_V1(pst_left);
PG_FUNCTION_INFO_V1(pst_right);
PG_FUNCTION_INFO_V1(pst_chars_to_array);

PG_FUNCTION_INFO_V1(pst_last_day);
PG_FUNCTION_INFO_V1(pst_next_day);

typedef enum {
    PST_ZERO       =   1,
    PST_SPACE      =   2,
    PST_PLUS       =   4,
    PST_MINUS      =   8,
    PST_STAR_WIDTH =  16,
    PST_SHARP      =  32,
    PST_WIDTH      =  64,
    PST_PRECISION  = 128,
    PST_STAR_PRECISION = 256
} PlaceholderTags;

typedef struct {
	int	flags;
	char		field_type;
	char		lenmod;
	int32		width;
	int32		precision;
} FormatPlaceholderData;

typedef FormatPlaceholderData *PlaceholderDesc;

/*
 * Static functions
 */
static char *json_string(char *str);
static int mb_string_info(text *str, char **sizes, int **positions);
static int seq_prefix_search(const char *name, /*const*/ char **array, int max);

/*
 * External
 */
extern PGDLLIMPORT char *days[];


static Datum 
castValueTo(Datum value, Oid targetTypeId, Oid inputTypeId)
{
	Oid		funcId;
	CoercionPathType	pathtype;
	FmgrInfo	finfo;
	Datum	   result;

	if (inputTypeId != UNKNOWNOID)
		pathtype = find_coercion_pathway(targetTypeId, inputTypeId, 
									COERCION_EXPLICIT, 
									&funcId);
	else
		pathtype = COERCION_PATH_COERCEVIAIO;
	
	switch (pathtype)
	{
		case COERCION_PATH_RELABELTYPE:
			result = value;
			break;
		case COERCION_PATH_FUNC:
			{
				Assert(OidIsValid(funcId));
				
				fmgr_info(funcId, &finfo);
				result = FunctionCall1(&finfo, value);
			}
			break;
		
		case COERCION_PATH_COERCEVIAIO:
			{
				Oid                     typoutput;
				Oid			typinput;
				bool            typIsVarlena;
				Oid		typIOParam;
				char 	*extval;
		        
				getTypeOutputInfo(inputTypeId, &typoutput, &typIsVarlena);
				extval = OidOutputFunctionCall(typoutput, value);
				
				getTypeInputInfo(targetTypeId, &typinput, &typIOParam);
				result = OidInputFunctionCall(typinput, extval, typIOParam, -1);
			}
			break;
		
		default:
			elog(ERROR, "failed to find conversion function from %s to %s",
					format_type_be(inputTypeId), format_type_be(targetTypeId));
			/* be compiler quiet */
			result = (Datum) 0;
	}
	
	return result;
}

/*
 * parse and verify sprintf parameter 
 *
 *      %[flags][width][.precision]specifier
 *
 */
static char *
parsePlaceholder(char *src, char *end_ptr, PlaceholderDesc pdesc, text *fmt)
{
	char		c;

	pdesc->field_type = '\0';
	pdesc->lenmod = '\0';
	pdesc->flags = 0;
	pdesc->width = 0;
	pdesc->precision = 0;

	while (src < end_ptr && pdesc->field_type == '\0')
	{
		c = *++src;

		switch (c)
		{
			case '0':
				CHECK_PAD('0', PST_ZERO);
				break;
			case ' ':
				CHECK_PAD(' ', PST_SPACE);
				break;
			case '+':
				CHECK_PAD('+', PST_PLUS);
				break;
			case '-':
				CHECK_PAD('-', PST_MINUS);
				break;
			case '*':
				CHECK_PAD('*', PST_STAR_WIDTH);
				break;
			case '#':
				CHECK_PAD('#', PST_SHARP);
				break;
			case 'o': case 'i': case 'e': case 'E': case 'f': 
			case 'g': case 'd': case 's': case 'x': case 'X': 
				pdesc->field_type = *src;
				break;
			case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				CHECK_PAD('9', PST_WIDTH);
				pdesc->width = c - '0';
				while (src < end_ptr && isdigit(src[1]))
					pdesc->width = pdesc->width * 10 + *++src - '0';
				break;
			case '.':
				if (src < end_ptr)
				{
					if (src[1] == '*')
					{
						CHECK_PAD('.', PST_STAR_PRECISION);
						src++;
						elog(NOTICE, "1");
					}
					else
					{
						bool valid = false;
					
						CHECK_PAD('.', PST_PRECISION);
						while (src < end_ptr && isdigit(src[1]))
						{
							pdesc->precision = pdesc->precision * 10 + *++src - '0';
							valid = true;
						}
						
						if (!valid)
							ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("broken sprinf format"),
								 errdetail("missing precision value")));
					}
				}
				else 
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("broken sprinf format"),
							 errdetail("missing precision value")));
				break;

			default:
				ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("unsupported sprintf format tag '%c'", c)));
		}
	}

	if (pdesc->field_type == '\0')
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("broken sprintf format")));

	return src;
}

static char *
currentFormat(StringInfo str, PlaceholderDesc pdesc)
{
	resetStringInfo(str);
	appendStringInfoChar(str,'%');
	
	if (pdesc->flags & PST_ZERO)
		appendStringInfoChar(str, '0');

	if (pdesc->flags & PST_MINUS)
		appendStringInfoChar(str, '-');

	if (pdesc->flags & PST_PLUS)
		appendStringInfoChar(str, '+');
		
	if (pdesc->flags & PST_SPACE)
		appendStringInfoChar(str, ' ');
		
	if (pdesc->flags & PST_SHARP)
		appendStringInfoChar(str, '#');

	if ((pdesc->flags & PST_WIDTH) || (pdesc->flags & PST_STAR_WIDTH))
		appendStringInfoChar(str, '*');
		
	if ((pdesc->flags & PST_PRECISION) || (pdesc->flags & PST_STAR_PRECISION))
		appendStringInfoString(str, ".*");
		
	if (pdesc->lenmod != '\0')
		appendStringInfoChar(str, pdesc->lenmod);

	appendStringInfoChar(str, pdesc->field_type);
	
	return str->data;
}

/*
 * Set width and precision when they are defined dynamicaly
 */
static 
int setWidthAndPrecision(PlaceholderDesc pdesc, FunctionCallInfoData *fcinfo, int current)
{

	/* 
	 * don't allow ambiguous definition
	 */
	if ((pdesc->flags & PST_WIDTH) && (pdesc->flags & PST_STAR_WIDTH))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("broken sprintf format"),
				 errdetail("ambiguous width definition")));

	if ((pdesc->flags & PST_PRECISION) && (pdesc->flags & PST_STAR_PRECISION))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("broken sprintf format"),
				 errdetail("ambiguous precision definition")));
	if (pdesc->flags & PST_STAR_WIDTH)
	{
		if (current >= PG_NARGS())
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("too few parameters")));
		
		if (PG_ARGISNULL(current))
			ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("null value not allowed"),
				 errhint("width (%dth) arguments is NULL", current)));
		
		pdesc->width = DatumGetInt32(castValueTo(PG_GETARG_DATUM(current), INT4OID, 
									get_fn_expr_argtype(fcinfo->flinfo, current)));
		/* reset flag */
		pdesc->flags ^= PST_STAR_WIDTH;
		pdesc->flags |= PST_WIDTH;
		current += 1;
	}
	
	if (pdesc->flags & PST_STAR_PRECISION)
	{
		if (current >= PG_NARGS())
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("too few parameters")));
		
		if (PG_ARGISNULL(current))
			ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("null value not allowed"),
				 errhint("width (%dth) arguments is NULL", current)));
		
		pdesc->precision = DatumGetInt32(castValueTo(PG_GETARG_DATUM(current), INT4OID, 
									get_fn_expr_argtype(fcinfo->flinfo, current)));
		/* reset flags */
		pdesc->flags ^= PST_STAR_PRECISION;
		pdesc->flags |= PST_PRECISION;
		current += 1;
	}
	
	return current;
}

/*
 * sprintf function - it is wrapper for libc vprintf function
 *
 *    ensure PostgreSQL -> C casting
 */
Datum
pst_sprintf(PG_FUNCTION_ARGS)
{
	text	   *fmt;
	StringInfo	str;
	StringInfo	format_str;
	char		*cp;
	int			i = 1;
	size_t		len;
	char		*start_ptr,
				*end_ptr;
	FormatPlaceholderData		pdesc;

	/* When format string is null, returns null */
	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	fmt = PG_GETARG_TEXT_PP(0);
	str = makeStringInfo();
	len = VARSIZE_ANY_EXHDR(fmt);
	start_ptr = VARDATA_ANY(fmt);
	end_ptr = start_ptr + len - 1;
	format_str = makeStringInfo();

	for (cp = start_ptr; cp <= end_ptr; cp++)
	{
		if (cp[0] == '%')
		{
			/* when cp is not pointer on last char, check %% */
			if (cp < end_ptr && cp[1] == '%')
			{
				appendStringInfoChar(str, cp[1]);
				cp++;
				continue;
			}

			if (i >= PG_NARGS())
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("too few parameters")));
						 
			cp = parsePlaceholder(cp, end_ptr, &pdesc, fmt);
			i = setWidthAndPrecision(&pdesc, fcinfo, i);

			if (!PG_ARGISNULL(i))
		        {
				Oid	valtype;
				Datum	value;

				/* append n-th value */
				value = PG_GETARG_DATUM(i);
				valtype = get_fn_expr_argtype(fcinfo->flinfo, i);
				
				/* convert value to target type */
				switch (pdesc.field_type)
				{
					case 'o': case 'd': case 'i': case 'x': case 'X':
						{
							int64	target_value;
							const char 		*format;
							
							pdesc.lenmod = 'l';
							target_value = DatumGetInt64(castValueTo(value, INT8OID, valtype));
							format = currentFormat(format_str, &pdesc);
							
							if ((pdesc.flags & PST_WIDTH) && (pdesc.flags & PST_PRECISION))
								appendStringInfo(str, format, pdesc.width, pdesc.precision, target_value);
							else if (pdesc.flags & PST_WIDTH)
								appendStringInfo(str, format, pdesc.width, target_value);
							else if (pdesc.flags & PST_PRECISION)
								appendStringInfo(str, format, pdesc.precision, target_value);
							else
								appendStringInfo(str, format, target_value);
						}
						break;
					case 'e': case 'f': case 'g': case 'G': case 'E':
						{
							float8	target_value;
							const char 		*format;
							
							target_value = DatumGetFloat8(castValueTo(value, FLOAT8OID, valtype));
							format = currentFormat(format_str, &pdesc);
							
							if ((pdesc.flags & PST_WIDTH) && (pdesc.flags & PST_PRECISION))
								appendStringInfo(str, format, pdesc.width, pdesc.precision, target_value);
							else if (pdesc.flags & PST_WIDTH)
								appendStringInfo(str, format, pdesc.width, target_value);
							else if (pdesc.flags & PST_PRECISION)
								appendStringInfo(str, format, pdesc.precision, target_value);
							else
								appendStringInfo(str, format, target_value);
						}
						break;
					case 's':
						{
							char		*target_value;
							const char 		*format;
							Oid                     typoutput;
							bool            typIsVarlena;

							getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
							target_value = OidOutputFunctionCall(typoutput, value);
							
							format = currentFormat(format_str, &pdesc);

							/* use wide chars if it is necessary */
							if (pg_database_encoding_max_length() > 1)
							{
								wchar_t *wformat;
								wchar_t	*wbuffer;
								size_t 	fmtlen = (strlen(format) + 1) * sizeof(wchar_t);
								size_t	len = strlen(target_value) + 1;
								
								wformat = palloc(fmtlen);
								char2wchar(wformat, fmtlen, format, strlen(format));
								wbuffer = palloc(len * sizeof(wchar_t));
								
								for (;;)
								{
									int	result;
									
									if ((pdesc.flags & PST_WIDTH) && (pdesc.flags & PST_PRECISION))
										result = swprintf(wbuffer, len, wformat, pdesc.width, 
															 pdesc.precision, target_value);
									else if (pdesc.flags & PST_WIDTH)
										result = swprintf(wbuffer, len, wformat, pdesc.width, target_value);
									else if (pdesc.flags & PST_PRECISION)
										result = swprintf(wbuffer, len, wformat, pdesc.precision, target_value);
									else
										result = swprintf(wbuffer, len, wformat, target_value);
									
									if (result != -1)
									{
										/* append result */
										appendStringInfo(str, "%ls", wbuffer);
										break;
									}
									else
									{
										/* increase buffer size and repeat */
										len *= 2;
										if ((len * sizeof(pg_wchar)) > MaxAllocSize)
											ereport(ERROR,
												(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
												 errmsg("out of memory")));
												 
										wbuffer = repalloc(wbuffer, len * sizeof(wchar_t) + 1);
										/* continue */
									}
								}
								
								pfree(wbuffer);
								pfree(wformat);
							}
							else
							{
								/* shortcut for one byte encoding */
								if ((pdesc.flags & PST_WIDTH) && (pdesc.flags & PST_PRECISION))
									appendStringInfo(str, format, pdesc.width, pdesc.precision, target_value);
								else if (pdesc.flags & PST_WIDTH)
									appendStringInfo(str, format, pdesc.width, target_value);
								else if (pdesc.flags & PST_PRECISION)
									appendStringInfo(str, format, pdesc.precision, target_value);
								else
									appendStringInfo(str, format, target_value);
								
								pfree(target_value);
							}
						}
						break;
				}
			}
			else
				/* return null when some argument is null */
				PG_RETURN_NULL();
			i++;
		}
		else
			appendStringInfoChar(str, cp[0]);
	}

	/* check if all arguments are used */
	if (i != PG_NARGS())
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("too many parameters")));

	PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}

/*
 * only wrapper
 */
Datum
pst_sprintf_nv(PG_FUNCTION_ARGS)
{
	return pst_sprintf(fcinfo);
}

/*
 * Format message - replace char % by parameter value
 *
 */
Datum
pst_format(PG_FUNCTION_ARGS)
{
	text	   *fmt;
	StringInfo	str;
	char		*cp;
	int			i = 1;
	size_t		len;
	char		*start_ptr,
				*end_ptr;

	/* When format string is null, returns null */
	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	fmt = PG_GETARG_TEXT_PP(0);
	str = makeStringInfo();
	len = VARSIZE_ANY_EXHDR(fmt);
	start_ptr = VARDATA_ANY(fmt);
	end_ptr = start_ptr + len - 1;

	for (cp = start_ptr; cp <= end_ptr; cp++)
	{
		if (cp[0] == '%')
		{

			/* when cp is not pointer on last char, check %% */
			if (cp < end_ptr && cp[1] == '%')
			{
				appendStringInfoChar(str, cp[1]);
				cp++;
				continue;
			}

			if (i >= PG_NARGS())
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("too few parameters")));

			if (!PG_ARGISNULL(i))
		        {
				Oid	valtype;
				Datum	value;
				Oid                     typoutput;
				bool            typIsVarlena;
		        
				/* append n-th value */
				value = PG_GETARG_DATUM(i);
				valtype = get_fn_expr_argtype(fcinfo->flinfo, i);

				getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
				appendStringInfoString(str, OidOutputFunctionCall(typoutput, value));
			}
			else
				appendStringInfoString(str, "NULL");
			i++;
		}
		else
			appendStringInfoChar(str, cp[0]);
	}

	/* check if all arguments are used */
	if (i != PG_NARGS())
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("too many parameters")));

        PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}

/*
 * Non variadic Format function - only wrapper
 *   We have to call variadic function, because we would to check format string.
 */
Datum
pst_format_nv(PG_FUNCTION_ARGS)
{
	return pst_format(fcinfo);
}

/*
 * Concat values to comma separated list. This function
 * is NULL safe. NULL values are skipped.
 */
Datum
pst_concat(PG_FUNCTION_ARGS)
{
	StringInfo	str;
	int	i;

	/* return NULL, if there are not any parameter */
	if (PG_NARGS() == 0)
		PG_RETURN_NULL();

	str = makeStringInfo();
	for(i = 0; i < PG_NARGS(); i++)
	{
		if (i > 0)
			appendStringInfoChar(str, ',');

		if (!PG_ARGISNULL(i))
		{
			Oid	valtype;
			Datum	value;
			Oid                     typoutput;
			bool            typIsVarlena;

			/* append n-th value */
			value = PG_GETARG_DATUM(i);
			valtype = get_fn_expr_argtype(fcinfo->flinfo, i);

			getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
			appendStringInfoString(str, OidOutputFunctionCall(typoutput, value));
		}
	}

	PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}

/*
 * Concat values to comma separated list. This function
 * is NULL safe. NULL values are skipped.
 */
Datum
pst_concat_ws(PG_FUNCTION_ARGS)
{
	StringInfo	str;
	int	i;
	char	*sepstr;
	
	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	/* return NULL, if there are not any parameter */
	if (PG_NARGS() == 1)
		PG_RETURN_NULL();

	sepstr = TextDatumGetCString(PG_GETARG_TEXT_P(0));

	str = makeStringInfo();
	for(i = 1; i < PG_NARGS(); i++)
	{
		if (i > 1)
			appendStringInfoString(str, sepstr);

		if (!PG_ARGISNULL(i))
		{
			Oid	valtype;
			Datum	value;
			Oid                     typoutput;
			bool            typIsVarlena;

			/* append n-th value */
			value = PG_GETARG_DATUM(i);
			valtype = get_fn_expr_argtype(fcinfo->flinfo, i);

			getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
			appendStringInfoString(str, OidOutputFunctionCall(typoutput, value));
		}
	}

	PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}


/*
 * Concat string with respect to SQL format. This is NULL safe.
 * NULLs values are transformated to "NULL" string.
 */
Datum
pst_concat_sql(PG_FUNCTION_ARGS)
{
	StringInfo	str;
	int	i;

	/* return NULL, if there are not any parameter */
	if (PG_NARGS() == 0)
		PG_RETURN_NULL();

	str = makeStringInfo();
	for(i = 0; i < PG_NARGS(); i++)
	{
		if (i > 0)
			appendStringInfoChar(str, ',');

		if (!PG_ARGISNULL(i))
		{
			Oid	valtype;
			Datum	value;
			Oid                     typoutput;
			bool            typIsVarlena;
			TYPCATEGORY	typcat;

			/* append n-th value */
			value = PG_GETARG_DATUM(i);
			valtype = get_fn_expr_argtype(fcinfo->flinfo, i);
			typcat = TypeCategory(valtype);

			if (typcat == 'N' || typcat == 'B')
			{
				getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
				appendStringInfoString(str, OidOutputFunctionCall(typoutput, value));
			}
			else
			{
				text	*txt;
				text	*quoted_txt;
			
				getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
				
				/* get text value and quotize */
				txt = cstring_to_text(OidOutputFunctionCall(typoutput, value));
				quoted_txt = DatumGetTextP(DirectFunctionCall1(quote_literal,
											    PointerGetDatum(txt)));
				appendStringInfoString(str, text_to_cstring(quoted_txt));
			}
		}
		else
			appendStringInfoString(str, "NULL");
	}

	PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}


/*
 * Concat string with respect to JSON format. This is NULL safe.
 * NULLs values are transformated to "null" string.
 * JSON uses lowercase characters for constants - see www.json.org
 */
Datum
pst_concat_js(PG_FUNCTION_ARGS)
{
	StringInfo	str;
	int	i;

	/* return NULL, if there are not any parameter */
	if (PG_NARGS() == 0)
		PG_RETURN_NULL();

	str = makeStringInfo();
	for(i = 0; i < PG_NARGS(); i++)
	{
		if (i > 0)
			appendStringInfoChar(str, ',');

		if (!PG_ARGISNULL(i))
		{
			Oid	valtype;
			Datum	value;
			Oid                     typoutput;
			bool            typIsVarlena;
			TYPCATEGORY	typcat;

			/* append n-th value */
			value = PG_GETARG_DATUM(i);
			valtype = get_fn_expr_argtype(fcinfo->flinfo, i);
			typcat = TypeCategory(valtype);

			if (typcat == 'N')
			{
				getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
				appendStringInfoString(str, OidOutputFunctionCall(typoutput, value));
			} else if (typcat == 'B')
			{
				bool	bvalue = PG_GETARG_BOOL(i);
				
				appendStringInfoString(str, bvalue ? "true" : "false");
			}
			else
			{
				getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
				appendStringInfo(str, "\"%s\"", json_string(OidOutputFunctionCall(typoutput, value)));			
			}
		}
		else
			appendStringInfoString(str, "null");
	}

	PG_RETURN_TEXT_P(CStringGetTextDatum(str->data));
}


/*
 * Returns first n chars. When n is negative, then
 * it returns chars from n+1 position.
 */
Datum
pst_left(PG_FUNCTION_ARGS)
{
	text *str = PG_GETARG_TEXT_PP(0);
	int	len = VARSIZE_ANY_EXHDR(str);
	char	*p = VARDATA_ANY(str);
	text   *result;
	int		n = PG_GETARG_INT32(1);
	
	if (len == 0 || n == 0)
		PG_RETURN_TEXT_P(CStringGetTextDatum(""));
	
	if (pg_database_encoding_max_length() > 1)
	{
		char	*sizes;
		int	*positions;
		
		len = mb_string_info(str, &sizes, &positions);
		
		if (n > 0)
		{
			n = n > len ? len : n;
			result = cstring_to_text_with_len(p, positions[n - 1] + sizes[n - 1]);
		}
		else
		{
			n = -n > len ? len : -n;
			result = cstring_to_text_with_len(p + positions[n - 1] + sizes[n - 1],  
									positions[len - 1] + sizes[len - 1] - positions[n - 1] - sizes[n - 1]);
		}
		
		pfree(positions);
		pfree(sizes);
	}
	else
	{
		if (n > 0)
		{
			n = n > len ? len : n;
			result = cstring_to_text_with_len(p, n);
		}
		else
		{
			n = -n > len ? len : -n;
			result = cstring_to_text_with_len(p + n, len - n);
		}
	}

	PG_RETURN_TEXT_P(result);
}


/*
 * Returns last n chars from string. When n is negative,
 * then returns string without last n chars.
 */
Datum
pst_right(PG_FUNCTION_ARGS)
{
	text *str = PG_GETARG_TEXT_PP(0);
	int	len = VARSIZE_ANY_EXHDR(str);
	char	*p = VARDATA_ANY(str);
	text   *result;
	int		n = PG_GETARG_INT32(1);
	
	if (len == 0 || n == 0)
		PG_RETURN_TEXT_P(CStringGetTextDatum(""));
	
	if (pg_database_encoding_max_length() > 1)
	{
		char	*sizes;
		int	*positions;
		
		len = mb_string_info(str, &sizes, &positions);
		
		if (n > 0)
		{
			n = n > len ? len : n;
			result = cstring_to_text_with_len(p + positions[len - n],
								positions[len - 1] + sizes[len - 1] - positions[len - n]);
		}
		else
		{
			n = -n > len ? len : -n;
			result = cstring_to_text_with_len(p, positions[len - n] + sizes[len - n] - 1);
		}
		
		pfree(positions);
		pfree(sizes);
	}
	else
	{
		if (n > 0)
		{
			n = n > len ? len : n;
			result = cstring_to_text_with_len(p + len - n, n);
		}
		else
		{
			n = -n > len ? len : -n;
			result = cstring_to_text_with_len(p, len - n);
		}
	}

	PG_RETURN_TEXT_P(result);
}


/*
 * Returns reversed string
 */
Datum
pst_rvrs(PG_FUNCTION_ARGS)
{
	text *str = PG_GETARG_TEXT_PP(0);
	text	*result;
	char	*p = VARDATA_ANY(str);
	int  len = VARSIZE_ANY_EXHDR(str);
	char	*data;
	int		i;

	result = palloc(len + VARHDRSZ);
	data = (char*) VARDATA(result);
	SET_VARSIZE(result, len + VARHDRSZ);
	
	if (pg_database_encoding_max_length() > 1)
	{
		char	*sizes;
		int	*positions;
		
		/* multibyte version */
		len = mb_string_info(str, &sizes, &positions);
		for (i = len - 1; i >= 0; i--)
		{
			memcpy(data, p + positions[i], sizes[i]);
			data += sizes[i];
		}
		
		pfree(positions);
		pfree(sizes);
	}
	else
	{
		/* single byte version */
		for (i = len - 1; i >= 0; i--)
			*data++ = p[i];
	}
	
	PG_RETURN_TEXT_P(result);
}


Datum
pst_chars_to_array(PG_FUNCTION_ARGS)
{
	text	*chars = PG_GETARG_TEXT_PP(0);
	ArrayBuildState *astate = NULL;
	int	*positions;
	char	*sizes;
	bool		is_mb;
	int	len;
	int		i;
	char		*p = VARDATA_ANY(chars);
	
	is_mb = pg_database_encoding_max_length() > 1;
	
	if (is_mb)
		len = mb_string_info(chars, &sizes, &positions);
	else
		len = VARSIZE_ANY_EXHDR(chars);

	if (len > 0)
	{
		for (i = 0; i < len; i++)
		{
			text	*chr;
		
			if (is_mb)
				chr = cstring_to_text_with_len(p + positions[i], 
										sizes[i]);
			else
				chr = cstring_to_text_with_len(p + i, 1);

			astate = accumArrayResult(astate,
							PointerGetDatum(chr),
							false,
							TEXTOID,
							CurrentMemoryContext);	
						
			pfree(chr);
		}
	
		if (is_mb)
		{
			pfree(positions);
			pfree(sizes);
		}
		
		PG_RETURN_ARRAYTYPE_P(makeArrayResult(astate, 
								CurrentMemoryContext));
	}
	else
		PG_RETURN_ARRAYTYPE_P(construct_empty_array(TEXTOID));
}

/*
 * Returns the first weekday that is greater than a date value.
 */
Datum
pst_next_day(PG_FUNCTION_ARGS)
{
	DateADT day = PG_GETARG_DATEADT(0);
	text *day_txt = PG_GETARG_TEXT_PP(1);
	const char *str = VARDATA_ANY(day_txt);
	int	len = VARSIZE_ANY_EXHDR(day_txt);
	int off;
	int d = -1;

	/*
	 * Oracle uses only 3 heading characters of the input.
	 * Ignore all trailing characters.
	 */
	if (len >= 3 && (d = seq_prefix_search(str, days, 3)) >= 0)
		goto found;

	CHECK_SEQ_SEARCH(-1, "DAY/Day/day");

found:
	off = d - j2day(day+POSTGRES_EPOCH_JDATE);

	PG_RETURN_DATEADT((off <= 0) ? day+off+7 : day + off);
}


/*
 * Returns last day of the month
 */
Datum
pst_last_day(PG_FUNCTION_ARGS)
{
	DateADT day = PG_GETARG_DATEADT(0);
	DateADT result;
	int y, m, d;

	j2date(day + POSTGRES_EPOCH_JDATE, &y, &m, &d);
	result = date2j(y, m+1, 1) - POSTGRES_EPOCH_JDATE;

	PG_RETURN_DATEADT(result - 1);
}


/*
 * Convert C string to JSON string
 */
static char *
json_string(char *str)
{
	char	len = strlen(str);
	char		*result, *wc;
	
	wc = result = palloc(len * 2 + 1);
	while (*str != '\0')
	{
		char	c = *str++;
		
		switch (c)
		{
			case '\t':
				*wc++ = '\\';
				*wc++ = 't';
				break;
			case '\b':
				*wc++ = '\\';
				*wc++ = 'b';
				break;
			case '\n':
				*wc++ = '\\';
				*wc++ = 'n';
				break;
			case '\r':
				*wc++ = '\\';
				*wc++ = 'r';
				break;
			case '\\':
				*wc++ = '\\';
				*wc++ = '\\';
				break;
			case '"':
				*wc++ = '\\';
				*wc++ = '"';
				break;
			default:
				*wc++ = c;
		}
	}
	*wc = '\0';
	return result;
}


/*
 * Returns length of string, size and position of every
 * multibyte char in string.
 */
static int
mb_string_info(text *str, char **sizes, int **positions)
{
	int r_len;
	int cur_size = 0;
	int sz;
	char *p;
	int cur = 0;

	p = VARDATA_ANY(str);
	r_len = VARSIZE_ANY_EXHDR(str);

	if (NULL != sizes)
		*sizes = palloc(r_len * sizeof(char));
	if (NULL != positions)
		*positions = palloc(r_len * sizeof(int));

	while (cur < r_len)
	{
		sz = pg_mblen(p);
		if (sizes)
			(*sizes)[cur_size] = sz;
		if (positions)
			(*positions)[cur_size] = cur;
		cur += sz;
		p += sz;
		cur_size += 1;
	}

	return cur_size;
}

static int
seq_prefix_search(const char *name, /*const*/ char **array, int max)
{
	int		i;

	if (!*name)
		return -1;

	for (i = 0; array[i]; i++)
	{
		if (pg_strncasecmp(name, array[i], max) == 0)
			return i;
	}
	return -1;	/* not found */
}
