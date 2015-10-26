/********************************************************************************************************************
# A Custom DSL for querying Hive. Note: Both files make up the DSL and Interpreter
********************************************************************************************************************/
/******************
# HiveTranslator.g4
******************/
grammar HiveTranslator;

start : (expr)+ ;
expr: TABLE ':' tables=tablenames #tableExpr
     | FIELD ':' fields=fieldnames #fieldExpr
     | NL #nl
     ;

TABLE: T A B L E ;
FIELD: F I E L D ;

fieldnames: (fieldName)+ NL #fieldNameExpr;

tablenames: (tableName)+ NL #tableNameExpr ;

tableName: (Identifier '.')? Identifier #tableNameSingle ;

fieldName: (Identifier '.' )? (Identifier '.') ? Identifier  #fieldNameSingle ;

Identifier: ('A'..'Z' | 'a'..'z' ) ( 'A'..'Z' | 'a'..'z' | '0'..'9' | '_')+;

WHITESPACE : ( '\t' | ' ' | '\u000C' )+ -> skip ;

COMMENT : '/*' .*? '*/' -> skip ;


NL : ('\r' | '\n')+ ;

fragment A:('a'|'A');
fragment B:('b'|'B');
fragment C:('c'|'C');
fragment D:('d'|'D');
fragment E:('e'|'E');
fragment F:('f'|'F');
fragment G:('g'|'G');
fragment H:('h'|'H');
fragment I:('i'|'I');
fragment J:('j'|'J');
fragment K:('k'|'K');
fragment L:('l'|'L');
fragment M:('m'|'M');
fragment N:('n'|'N');
fragment O:('o'|'O');
fragment P:('p'|'P');
fragment Q:('q'|'Q');
fragment R:('r'|'R');
fragment S:('s'|'S');
fragment T:('t'|'T');
fragment U:('u'|'U');
fragment V:('v'|'V');
fragment W:('w'|'W');
fragment X:('x'|'X');
fragment Y:('y'|'Y');
fragment Z:('z'|'Z');


/***************************
# HiveSimpleInterpreter.java 
***************************/
package org.apache.zeppelin.hive.dsl;

import org.apache.zeppelin.hive.HiveInterpreter;
import java.io.ByteArrayInputStream;
import java.io.IOException;

import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.ANTLRInputStream;
import java.nio.charset.Charset;
import java.util.Properties;
import org.apache.zeppelin.interpreter.InterpreterResult;
import org.apache.zeppelin.interpreter.Interpreter;
import org.apache.zeppelin.interpreter.InterpreterContext;
import org.apache.zeppelin.interpreter.InterpreterPropertyBuilder;

/**
 * Simple interpreter that extends Hive's interpreter with a more powerful interface.
 * @author rusty
 *
 */
public class HiveSimpleInterpreter extends HiveInterpreter {
  
  public HiveSimpleInterpreter(Properties property) {
    super(property);
  }


  static final String HIVESERVER_URL = "hive.hiveserver2.url";
  static final String HIVESERVER_USER = "hive.hiveserver2.user";
  static final String HIVESERVER_PASSWORD = "hive.hiveserver2.password";

  static {
    Interpreter.register(
      "my_project",
      "hive",
      HiveSimpleInterpreter.class.getName(),
      new InterpreterPropertyBuilder()
        .add(HIVESERVER_URL, "jdbc:hive2://localhost:10000", "The URL for HiveServer2.")
        .add(HIVESERVER_USER, "hive", "The hive user")
        .add(HIVESERVER_PASSWORD, "", "The password for the hive user").build());
  }

  private String translate(String cmd) {
    ByteArrayInputStream bios = new ByteArrayInputStream(cmd.getBytes( Charset.defaultCharset() ));
    HiveTranslatorLexer lexer;
    try {
      lexer = new HiveTranslatorLexer(new ANTLRInputStream(bios));
    } catch (IOException ex) {
      throw new RuntimeException(ex);
    };
    
    CommonTokenStream tokens = new CommonTokenStream(lexer);
    HiveTranslatorParser parser = new HiveTranslatorParser(tokens);
    ParserRuleContext tree = parser.start();
    
    MainVisitor visitor = new MainVisitor();
    
    return (String) visitor.visit(tree);
  }
  
  @Override
  public InterpreterResult interpret(String cmd, InterpreterContext contextInterpreter) 
  {
    String cmd_fmt = cmd.toLowerCase().trim();
    if (cmd_fmt.startsWith("table") || cmd_fmt.startsWith("field"))
      return super.interpret(translate(cmd), contextInterpreter);
    return super.interpret(cmd, contextInterpreter);
  }

}
