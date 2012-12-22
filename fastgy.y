%{
/** Parse a FASTG file. */
%}

%defines
%error-verbose
%union {
	unsigned long long i;
	char* s;
}
%token ALT DIGRAPH TANDEM GAP
%token <i> NONNEGATIVE_INTEGER_STRING
%token <s> BASE_STRING
%token <s> AMBIGUOUS_BASE_STRING
%token <s> NAME_STRING
%token VALUE_STRING
%type <s> canonical_base_string
%type <s> embedded_digraph_string
%type <s> ambiguity_string
%type <s> tandem_string
%type <s> gap_object_string
%type <s> stuffed_gap_object_string
%start super_digraph_string

%{
#include <stdio.h>

/** The current line number. */
extern int yylineno;

/** The next lexeme. */
extern const char* yytext;

void yyerror(const char* s)
{
	fprintf(stderr, "error: %u: %s near `%s'\n",
		yylineno, s, yytext);
}

int yywrap()
{
	return 1;
}

%}

%%

property
	: NAME_STRING '=' VALUE_STRING
		{ free($1); }
	| NAME_STRING
		{ free($1); }

property_string
	: property
	| property_string ',' property

maybe_property_string
	: /*empty*/
	| ':' property_string

name_strings
	: NAME_STRING
		{ free($1); }
	| name_strings ',' NAME_STRING
		{ free($3); }

maybe_name_strings_property_string
	: /*empty*/
	| ':' name_strings maybe_property_string

canonical_base_string
	: BASE_STRING
		{ $$ = $1; }
	| AMBIGUOUS_BASE_STRING
		{ $$ = $1; }

fasta_string
	: '>' NAME_STRING maybe_name_strings_property_string ';'
		BASE_STRING
		{ free($2); free($5); }

maybe_tick
	: /*empty*/
	| '\''

digraph_string
	: fasta_string maybe_tick
	| digraph_string fasta_string maybe_tick

base_strings
	: BASE_STRING maybe_property_string
		{ free($1); }
	| base_strings ',' BASE_STRING maybe_property_string
		{ free($3); }

embedded_digraph_string
	: canonical_base_string '[' NONNEGATIVE_INTEGER_STRING
		DIGRAPH maybe_property_string '|' super_digraph_string ']'
		{ $$ = $1; }

ambiguity_string
	: canonical_base_string '[' NONNEGATIVE_INTEGER_STRING
		ALT maybe_property_string '|' base_strings ']'
		{ $$ = $1; }

tandem_string
	: canonical_base_string '[' NONNEGATIVE_INTEGER_STRING
		TANDEM maybe_property_string '|' BASE_STRING ']'
		{ $$ = $1; free($7); }

gap_object_string
	: canonical_base_string '[' NONNEGATIVE_INTEGER_STRING
		GAP maybe_property_string ']'
		{ $$ = $1; }

stuffed_gap_object_string
	: canonical_base_string '[' NONNEGATIVE_INTEGER_STRING
		GAP maybe_property_string '|' digraph_string ']'
		{ $$ = $1; }

basic_fasta_string
	: BASE_STRING
		{ fputs($1, stdout); free($1); }
	| embedded_digraph_string
		{ fputs($1, stdout); free($1); }
	| ambiguity_string
		{ fputs($1, stdout); free($1); }
	| tandem_string
		{ fputs($1, stdout); free($1); }
	| gap_object_string
		{ fputs($1, stdout); free($1); }
	| stuffed_gap_object_string
		{ fputs($1, stdout); free($1); }

basic_fasta_strings
	: basic_fasta_string
	| basic_fasta_strings basic_fasta_string

super_fasta_string
	: '>' NAME_STRING maybe_name_strings_property_string ';'
		{ printf(">%s\n", $2); free($2); }
		basic_fasta_strings
		{ putchar('\n'); }

super_digraph_string
	: super_fasta_string
	| super_digraph_string super_fasta_string
