/** Scan a FASTG file. */

%option nodefault
%option yylineno

%{
#include "fastgy.h"
%}

%%

[ \t\n]+ /* White space */
^#.*$ /* Comment */

"," return ',';
":" return ':';
";" return ';';
"=" return '=';
">" return '>';
"[" return '[';
"]" return ']';
"|" return '|';

":alt"     return ALT;
":digraph" return DIGRAPH;
":gap"     return GAP;
":tandem"  return TANDEM;

0|[1-9][0-9]* {
	yylval.i = atoll(yytext);
	return NONNEGATIVE_INTEGER_STRING;
}

[ACGT]+  yylval.s = strdup(yytext); return BASE_STRING;
[ACGTN]+ yylval.s = strdup(yytext); return AMBIGUOUS_BASE_STRING;

[a-zA-Z0-9_]+          yylval.s = strdup(yytext); return NAME_STRING;
"("[0-9,.]+")"         return VALUE_STRING;
\"[a-zA-Z0-9_()., ]+\" return VALUE_STRING;

. {
	yyerror("Unexpected character");
	exit(EXIT_FAILURE);
}

%%
