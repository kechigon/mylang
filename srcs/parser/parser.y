%{
  #include <cstdio>
  #include <iostream>
  #include <string>
  #include "nodes.h"
  using namespace std;

  Node* program;
  int yylex();
  extern FILE *yyin;
  void yyerror(const char *s);

%}

%union {
  long lval;
  double dval;
  char* sval;
  Node* nodes;
}

%token <lval> INTLITERAL
%token <dval> DOUBLELITERAL
%token <sval> STRINGLITERAL
%token <sval> IDENTIFIER

%token EQUAL
       NOT_EQUAL
       MORE_EQUAL
       LESS_EQUAL
       MORE
       LESS
       SUBST
       PLUS
       MINUS
       MULT
       DIV
       AND
       MOD
       OR
       ADD_SUBST
       SUBT_SUBST
       MULT_SUBST
       DIV_SUBST
       MOD_SUBST
       RETURN
       DOT
       COMMA
       INPUT
       OUTPUT
       IF
       ELSE
       FOR
       WHILE
       BREAK
       CONTINUE
       LEFT_PAREN
       RIGHT_PAREN
       LEFT_BRACE
       RIGHT_BRACE
       RIGHT_BRACKET
       INT
       DOUBLE
       STRING
       VOID
       SEMICOLON
       EOL
%token END 0 
%type <nodes> program
%type <nodes> blocks
%type <nodes> func_blocks
%type <nodes> func_block
%type <nodes> elements
%type <nodes> element
%type <nodes> element_content
%type <nodes> declaration
%type <nodes> declaration_subst_calc
%type <nodes> input_output
%type <nodes> outputs
%type <nodes> identifiers
%type <nodes> subst_calc
%type <nodes> subst_calc_2
%type <nodes> expression
%type <nodes> monomial
%type <nodes> if_stmt
%type <nodes> else_if_stmts
%type <nodes> else_if_stmt
%type <nodes> for_stmt
%type <nodes> func_exe
%type <nodes> args
%type <nodes> types
%right SUBST ADD_SUBST SUBT_SUBST MULT_SUBST DIV_SUBST MOD_SUBST
%left AND OR
%left EQUAL NOT_EQUAL MORE_EQUAL LESS_EQUAL MORE LESS
%left PLUS MINUS
%left MULT DIV MOD
%left UMINUS

%%
program:
  blocks {
    cout << "program" << endl;
    program = $1;
  };

blocks:
  elements {
    cout << "blocks" << endl;
    $$ = $1;
  }
  |
  eols elements {
    cout << "blocks eols" << endl;
    $$ = $2;
  }
  |
  func_blocks elements {
    cout << "blocks with func_block" << endl;
    $$ = $1; $$ -> addBrother($2);
  }
  |
  eols func_blocks elements {
    cout << "blocks with func_block eols" << endl;
    $$ = $2; $$ -> addBrother($3);
  };

func_blocks:
  func_blocks func_block {
    cout << "func_block mult" << endl;
    $$ = $1; $$ -> addBrother(Node::getList($2));
  }
  |
  func_block {
    cout << "func_block one time" << endl;
    $$ = Node::getList($1);
  };

func_block:
  types IDENTIFIER LEFT_PAREN args RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE eols {
    cout << "func_block eols" << endl;
    $$ = Node::make_list(5, StringNode::Create("FUNC"), $1, StringNode::Create($2), $4, $9);
  }
  |
  types IDENTIFIER LEFT_PAREN RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE eols {
    cout << "func_block no args eols" << endl;
    $$ = Node::make_list(4, StringNode::Create("FUNC"), $1, StringNode::Create($2), $8);
  }
  |
  VOID IDENTIFIER LEFT_PAREN args RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE eols {
    cout << "void func_block eols" << endl;
    $$ = Node::make_list(5, StringNode::Create("FUNC"), StringNode::Create("VOID"), StringNode::Create($2), $4, $9);
  }
  |
  VOID IDENTIFIER LEFT_PAREN RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE eols {
    cout << "void func_block no args eols" << endl;
    $$ = Node::make_list(4, StringNode::Create("FUNC"), StringNode::Create("VOID"), StringNode::Create($2), $8);
  };

elements:
  elements element {
    cout << "elements repeat" << endl;
    $$ = $1; $$ -> addBrother($2);
  }
  |
  element {
    cout << "elements" << endl;
    $$ = Node::getList($1);
  };

element:
  element_content eols {
    cout << "element eols" << endl;
    $$ = $1;
  }
  |
  element_content END {
    cout << "element END" << endl;
    $$ = $1;
  };

element_content:
  declaration {
    cout << "element_content declaretion" << endl;
    $$ = $1;
  }
  |
  input_output {
    cout << "element_content input_output" << endl;
    $$ = $1;
  }
  |
  subst_calc {
    cout << "element_content subst_calc" << endl;
    $$ = $1;
  }
  |
  subst_calc_2 {
    cout << "element_content subst_calc_2" << endl;
    $$ = $1;
  }
  |
  if_stmt {
    cout << "element_content if_stmt" << endl;
    $$ = $1;
  }
  |
  WHILE LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "element_content while_stmt" << endl;
    $$ = Node::make_list(3, StringNode::Create("WHILE"), $3, $8);
  }
  |
  for_stmt {
    cout << "element_content for_stmt" << endl;
    $$ = $1;
  }
  |
  BREAK {
    cout << "element_content BREAK" << endl;
    $$ = StringNode::Create("BREAK");
  }
  |
  CONTINUE {
    cout << "element_content CONTINUE" << endl;
    $$ = StringNode::Create("CONTINUE");
  }
  |
  RETURN expression {
    cout << "element_content RETURN expression" << endl;
    $$ = Node::make_list(2, StringNode::Create("RETURN"), $2);
  }
  |
  RETURN STRINGLITERAL {
    cout << "element_content RETURN STRINGLITERAL" << endl;
    string text = $2;
    $$ = Node::make_list(2, StringNode::Create("RETURN"), StringNode::Create(text.substr(1, text.size()-2)));
    ((StringNode*)($$->getNext()))->setIsLiteral();
  }
  |
  func_exe {
    cout << "element_content func_exe" << endl;
    $$ = $1;
  }
  |
  SEMICOLON {
    cout << "element_content SEMICOLON" << endl;
    $$ = StringNode::Create("NEWLINE");
  };

declaration:
  types identifiers {
    cout << "declaration identifiers" << endl;
    $$ = Node::make_list(3, StringNode::Create("DECL"), $1, $2);
  }
  |
  declaration_subst_calc {
    cout << "declaration declaration_subst_calc" << endl;
    $$ = $1;
  };

declaration_subst_calc:
  types subst_calc {
    cout << "declaration_subst_calc" << endl;
    $$ = Node::make_list(3, StringNode::Create("DECL_SUBST"), $1, $2);
  };

input_output:
  INPUT identifiers {
    cout << "input_output input" << endl;
    $$ = Node::make_list(2, StringNode::Create("INPUT"), $2);
  }
  |
  outputs {
    cout << "input_output outputs" << endl;
    $$ = $1;
  };

outputs:
  outputs OUTPUT expression {
    cout << "outputs expression mult" << endl;
    $$ = $1; $$ -> addBrother(Node::make_list(2, StringNode::Create("OUTPUT"), $3));
  }
  |
  outputs OUTPUT STRINGLITERAL {
    cout << "outputs STRINGLITERAL mult" << endl;
    string text = $3;
    $$ = $1; $$ -> addBrother(Node::make_list(2, StringNode::Create("OUTPUT"), StringNode::Create(text.substr(1, text.size()-2))));
    Node *node = $$;
    while(node->getNext() != NULL) {
      node = node->getNext();
    }
    ((StringNode*)node)->setIsLiteral();
  }
  |
  OUTPUT expression {
    cout << "outputs expression" << endl;
    $$ = Node::make_list(2, StringNode::Create("OUTPUT"), $2);
  }
  |
  OUTPUT STRINGLITERAL {
    cout << "outputs STRINGLITERAL" << endl;
    string text = $2;
    $$ = Node::make_list(2, StringNode::Create("OUTPUT"), StringNode::Create(text.substr(1, text.size()-2)));
    ((StringNode*)($$->getNext()))->setIsLiteral();
  };

identifiers:
  identifiers COMMA IDENTIFIER {
    cout << "identifiers mult " << $3 << endl;
    $$ = $1; $$ -> addBrother(StringNode::Create($3));
  }
  |
  identifiers COMMA IDENTIFIER DOT INTLITERAL {
    cout << "identifiers mult array INT" << $3 << " " << $5 << endl;
    $$ = $1; $$ -> addBrother(ArrayElementNode::Create($3, $5));
  }
  |
  identifiers COMMA IDENTIFIER DOT IDENTIFIER {
    cout << "identifiers mult array IDENTIFIER" << $3 << " " << $5 << endl;
    $$ = $1; $$ -> addBrother(ArrayElementNode::Create($3, $5));
  }
  |
  IDENTIFIER {
    cout << "identifiers one " << $1 << endl;
    $$ = StringNode::Create($1);
  }
  |
  IDENTIFIER DOT INTLITERAL {
    cout << "identifiers one array INT " << $1 << " " << $3 << endl;
    $$ = ArrayElementNode::Create($1, $3);
  }
  |
  IDENTIFIER DOT IDENTIFIER {
    cout << "identifiers one array IDENTIFIER" << $1 << " " << $3 << endl;
    $$ = ArrayElementNode::Create($1, $3);
  };

subst_calc:
  identifiers SUBST expression {
    cout << "sbstcalc SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("SUBST"), $1, $3);
  }
  |
  identifiers SUBST STRINGLITERAL {
    cout << "subst_calc SUBST STRINGLITERAL" << endl;
    string text = $3;
    $$ = Node::make_list(3, StringNode::Create("SUBST"), $1, StringNode::Create(text.substr(1, text.size()-2)));
    ((StringNode*)($$->getNext()->getNext()))->setIsLiteral();
  };

subst_calc_2:
  identifiers ADD_SUBST expression {
    cout << "subst_calc_2 ADD_SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("ADD_SUBST"), $1, $3);
  }
  |
  identifiers SUBT_SUBST expression {
    cout << "subst_calc_2 SUBT_SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("SUBT_SUBST"), $1, $3);
  }
  |
  identifiers MULT_SUBST expression {
    cout << "subst_calc_2 MULT_SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("MULT_SUBST"), $1, $3);
  }
  |
  identifiers DIV_SUBST expression {
    cout << "subst_calc_2 DIV_SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("DIV_SUBST"), $1, $3);
  }
  |
  identifiers MOD_SUBST expression {
    cout << "subst_calc_2 MOD_SUBST" << endl;
    $$ = Node::make_list(3, StringNode::Create("MOD_SUBST"), $1, $3);
  };

expression:
  expression PLUS expression {
    cout << "expression PULS" << endl;
    $$ = Node::make_list(3, StringNode::Create("PULS"), $1, $3);
  }
  |
  expression MINUS expression {
    cout << "expression MINUS" << endl;
    $$ = Node::make_list(3, StringNode::Create("MINUS"), $1, $3);
  }
  |
  expression MULT expression {
    cout << "expression MULT" << endl;
    $$ = Node::make_list(3, StringNode::Create("MULT"), $1, $3);
  }
  |
  expression DIV expression {
    cout << "expression DIV" << endl;
    $$ = Node::make_list(3, StringNode::Create("DIV"), $1, $3);
  }
  |
  expression MOD expression {
    cout << "expression MOD" << endl;
    $$ = Node::make_list(3, StringNode::Create("MOD"), $1, $3);
  }
  |
  expression EQUAL expression {
    cout << "expression EQUAL" << endl;
    $$ = Node::make_list(3, StringNode::Create("EQUAL"), $1, $3);
  }
  |
  expression NOT_EQUAL expression {
    cout << "expression NOT_EQUAL" << endl;
    $$ = Node::make_list(3, StringNode::Create("NOT_EQUAL"), $1, $3);
  }
  |
  expression MORE_EQUAL expression {
    cout << "expression MORE_EQUAL" << endl;
    $$ = Node::make_list(3, StringNode::Create("MORE_EQUAL"), $1, $3);
  }
  |
  expression LESS_EQUAL expression {
    cout << "expression LESS_EQUAL" << endl;
    $$ = Node::make_list(3, StringNode::Create("LESS_EQUAL"), $1, $3);
  }
  |
  expression MORE expression {
    cout << "expression MORE" << endl;
    $$ = Node::make_list(3, StringNode::Create("MORE"), $1, $3);
  }
  |
  expression LESS expression {
    cout << "expression LESS" << endl;
    $$ = Node::make_list(3, StringNode::Create("LESS"), $1, $3);
  }
  |
  expression AND expression {
    cout << "expression AND" << endl;
    $$ = Node::make_list(3, StringNode::Create("AND"), $1, $3);
  }
  |
  expression OR expression {
    cout << "expression OR" << endl;
    $$ = Node::make_list(3, StringNode::Create("OR"), $1, $3);
  }
  |
  monomial {
    cout << "expression monomial" << endl;
    $$ = $1;
  }
  |
  MINUS expression %prec UMINUS {
    cout << "expression UMINUS" << endl;
    $$ = Node::make_list(2, StringNode::Create("UMINUS"), $2);
  }
  |
  LEFT_PAREN expression RIGHT_PAREN {
    cout << "expression PAREN" << endl;
    $$ = $2;
  };

monomial:
  INTLITERAL {
    cout << "monomial " << $1 << endl;
    $$ = IntNode::Create($1);
  }
  |
  DOUBLELITERAL {
    cout << "monomial " << $1 << endl;
    $$ = DoubleNode::Create($1);
  }
  |
  IDENTIFIER {
    cout << "monomial " << $1 << endl;
    $$ = StringNode::Create($1);
  }
  |
  IDENTIFIER DOT INTLITERAL {
    cout << "monomial " << $1 << " " << $3 << endl;
    $$ = ArrayElementNode::Create($1, $3);
  }
  |
  IDENTIFIER DOT IDENTIFIER {
    cout << "monomial " << $1 << " " << $3 << endl;
    $$ = ArrayElementNode::Create($1, $3);
  }
  |
  func_exe {
    cout << "monomial func_exe" << endl;
    $$ = $1;
  };

if_stmt:
  IF LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACKET {
    cout << "if_stmt" << endl;
    $$ = Node::make_list(3, StringNode::Create("IF"), $3, $8);
  }
  |
  IF LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE EOL ELSE EOL LEFT_BRACE EOL elements RIGHT_BRACKET {
    cout << "if_stmt else" << endl;
    $$ = Node::make_list(5, StringNode::Create("IF"), $3, $8, StringNode::Create("ELSE"), $15);
  }
  |
  IF LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE EOL else_if_stmts RIGHT_BRACKET{
    cout << "if_stmt elseif_stmts_end" << endl;
    $$ = Node::make_list(4, StringNode::Create("IF"), $3, $8, $11);
  }
  |
  IF LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE EOL else_if_stmts RIGHT_BRACE EOL ELSE EOL LEFT_BRACE EOL elements RIGHT_BRACKET {
    cout << "if_stmt else_if_stmts_mid else" << endl;
    $$ = Node::make_list(6, StringNode::Create("IF"), $3, $8, $11, StringNode::Create("ELSE"), $18);
  };

else_if_stmts:
  else_if_stmts RIGHT_BRACE EOL else_if_stmt {
    cout << "else_if_stmts mult" << endl;
    $$ = $1; $$ -> addBrother(Node::getList($4));
  }
  |
  else_if_stmt {
    cout << "else_if_stmts" << endl;
    $$ = Node::getList($1);
  };

  else_if_stmt:
  ELSE IF LEFT_PAREN expression RIGHT_PAREN EOL LEFT_BRACE EOL elements {
    cout << "else_if_stmt" << endl;
    $$ = Node::make_list(3, StringNode::Create("ELSE_IF"), $4, $9);
  };

for_stmt:
  FOR LEFT_PAREN declaration_subst_calc COMMA expression COMMA subst_calc RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt declaration_subst_calc subst_calc" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  }
  |
  FOR LEFT_PAREN declaration_subst_calc COMMA expression COMMA subst_calc_2 RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt declaration_subst_calc subst_calc_2" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  }
  |
  FOR LEFT_PAREN subst_calc COMMA expression COMMA subst_calc RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt subst_calc subst_calc" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  }
  |
  FOR LEFT_PAREN subst_calc COMMA expression COMMA subst_calc_2 RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt subst_calc subst_calc_2" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  }
  |
  FOR LEFT_PAREN subst_calc_2 COMMA expression COMMA subst_calc RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt subst_calc_2 subst_calc" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  }
  |
  FOR LEFT_PAREN subst_calc_2 COMMA expression COMMA subst_calc_2 RIGHT_PAREN EOL LEFT_BRACE EOL elements RIGHT_BRACE {
    cout << "for_stmt subst_calc_2 subst_calc_2" << endl;
    $$ = Node::make_list(5, StringNode::Create("FOR"), $3, $5, $12, $7);
  };

func_exe:
  IDENTIFIER LEFT_PAREN identifiers RIGHT_PAREN {
    cout << "func_exe identifiers" << endl;
    $$ = Node::make_list(3, StringNode::Create("FUNC_EXE"), StringNode::Create($1), $3);
  }
  |
  IDENTIFIER LEFT_PAREN RIGHT_PAREN {
    cout << "func_exe no identifiers" << endl;
    $$ = Node::make_list(2, StringNode::Create("FUNC_EXE"), StringNode::Create($1));
  };

args:
  args COMMA types IDENTIFIER {
    cout << "args mult" << endl;
    $$ = $1; $$ -> addBrother(Node::make_list(2, $3, StringNode::Create($4)));
  }
  |
  types IDENTIFIER {
    cout << "args" << endl;
    $$ = Node::make_list(2, $1, StringNode::Create($2));
  };

types:
  INT {
    cout << "types INT" << endl;
    $$ = StringNode::Create("INT");
  }
  |
  DOUBLE {
    cout << "types DOUBLE" << endl;
    $$ = StringNode::Create("DOUBLE");
  }
  |
  STRING {
    cout << "types STRING" << endl;
    $$ = StringNode::Create("STRING");
  };

eols:
  eols EOL
  |
  EOL;
%%

void yyerror(const char *s) {
  cout << "parse error ! Message: " << s << endl;

  exit(-1);
}