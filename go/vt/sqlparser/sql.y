/*
Copyright 2019 The Vitess Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

%{
package sqlparser

import "fmt"
//import "runtime/debug"

func setParseTree(yylex interface{}, stmt Statement) {
  yylex.(*Tokenizer).ParseTree = stmt
}

func setAllowComments(yylex interface{}, allow bool) {
  yylex.(*Tokenizer).AllowComments = allow
}

func incNesting(yylex interface{}) bool {
  yylex.(*Tokenizer).nesting++
  if yylex.(*Tokenizer).nesting == 200 {
    return true
  }
  return false
}

func decNesting(yylex interface{}) {
  yylex.(*Tokenizer).nesting--
}

func statementSeen(yylex interface{}) {
  if yylex.(*Tokenizer).stopAfterFirstStmt {
    yylex.(*Tokenizer).stopped = true
  }
}

func yyPosition(yylex interface{}) int {
  return yylex.(*Tokenizer).Position
}

func yyOldPosition(yylex interface{}) int {
  return yylex.(*Tokenizer).OldPosition
}

func yySpecialCommentMode(yylex interface{}) bool {
  tkn := yylex.(*Tokenizer)
  return tkn.specialComment != nil
}

%}

%union {
  empty         struct{}
  statement     Statement
  selStmt       SelectStatement
  ddl           *DDL
  ddls          []*DDL
  ins           *Insert
  byt           byte
  bytes         []byte
  bytes2        [][]byte
  str           string
  int           int
  strs          []string
  selectExprs   SelectExprs
  selectExpr    SelectExpr
  columns       Columns
  statements    Statements
  partitions    Partitions
  colName       *ColName
  tableExprs    TableExprs
  tableExpr     TableExpr
  subquery      *Subquery
  simpleTableExpr  SimpleTableExpr
  joinCondition JoinCondition
  triggerName   TriggerName
  tableName     TableName
  tableNames    TableNames
  procedureName ProcedureName
  indexHints    *IndexHints
  asOf          *AsOf
  expr          Expr
  exprs         Exprs
  boolVal       BoolVal
  boolean       bool
  sqlVal        *SQLVal
  colTuple      ColTuple
  values        Values
  valTuple      ValTuple
  whens         []*When
  when          *When
  orderBy       OrderBy
  order         *Order
  limit         *Limit
  assignExprs   AssignmentExprs
  assignExpr    *AssignmentExpr
  setVarExprs   SetVarExprs
  setVarExpr    *SetVarExpr
  setScope      SetScope
  colIdent      ColIdent
  colIdents     []ColIdent
  tableIdent    TableIdent
  convertType   *ConvertType
  aliasedTableName *AliasedTableExpr
  TableSpec  *TableSpec
  columnType    ColumnType
  columnOrder   *ColumnOrder
  triggerOrder  *TriggerOrder
  colKeyOpt     ColumnKeyOption
  optVal        Expr
  LengthScaleOption LengthScaleOption
  columnDefinition *ColumnDefinition
  indexDefinition *IndexDefinition
  indexInfo     *IndexInfo
  indexOption   *IndexOption
  indexOptions  []*IndexOption
  flushOption   *FlushOption
  indexColumn   *IndexColumn
  indexColumns  []*IndexColumn
  constraintDefinition *ConstraintDefinition
  constraintInfo ConstraintInfo
  ReferenceAction ReferenceAction
  partDefs      []*PartitionDefinition
  partDef       *PartitionDefinition
  partSpec      *PartitionSpec
  showFilter    *ShowFilter
  frame         *Frame
  frameExtent   *FrameExtent
  frameBound    *FrameBound
  caseStatementCases []CaseStatementCase
  caseStatementCase CaseStatementCase
  ifStatementConditions []IfStatementCondition
  ifStatementCondition IfStatementCondition
  signalInfo SignalInfo
  signalInfos []SignalInfo
  signalConditionItemName SignalConditionItemName
  declareHandlerAction DeclareHandlerAction
  declareHandlerCondition DeclareHandlerCondition
  declareHandlerConditions []DeclareHandlerCondition
  procedureParam ProcedureParam
  procedureParams []ProcedureParam
  characteristic Characteristic
  characteristics []Characteristic
  charsetCollate *CharsetAndCollate
  charsetCollates []*CharsetAndCollate
  Fields *Fields
  Lines	*Lines
  EnclosedBy *EnclosedBy
  tableAndLockType *TableAndLockType
  tableAndLockTypes TableAndLockTypes
  lockType LockType
  accountName AccountName
  accountNames []AccountName
  accountRenames []AccountRename
  authentication *Authentication
  accountWithAuth AccountWithAuth
  accountsWithAuth []AccountWithAuth
  tlsOptionItem TLSOptionItem
  tlsOptionItems []TLSOptionItem
  accountLimitItem AccountLimitItem
  accountLimitItems []AccountLimitItem
  passLockItem PassLockItem
  passLockItems []PassLockItem
  grantPrivilege Privilege
  grantPrivileges []Privilege
  grantObjectType GrantObjectType
  privilegeLevel PrivilegeLevel
  grantAssumption *GrantUserAssumption
  with *With
  window Window
  over *Over
  windowDef *WindowDef
}

%token LEX_ERROR
%left <bytes> UNION
%token <bytes> SELECT STREAM INSERT UPDATE DELETE FROM WHERE GROUP HAVING ORDER BY LIMIT OFFSET FOR CALL
%token <bytes> ALL DISTINCT AS EXISTS ASC DESC INTO DUPLICATE DEFAULT SET LOCK UNLOCK KEYS OF
%token <bytes> OUTFILE DATA LOAD LINES TERMINATED ESCAPED ENCLOSED OPTIONALLY STARTING
%right <bytes> UNIQUE KEY
%token <bytes> SYSTEM_TIME
%token <bytes> VALUES LAST_INSERT_ID SQL_CALC_FOUND_ROWS
%token <bytes> NEXT VALUE SHARE MODE
%token <bytes> SQL_NO_CACHE SQL_CACHE
%left <bytes> JOIN STRAIGHT_JOIN LEFT RIGHT INNER OUTER CROSS NATURAL USE FORCE
%left <bytes> ON USING
%token <empty> '(' ',' ')' '@'
%token <bytes> ID HEX STRING INTEGRAL FLOAT HEXNUM VALUE_ARG LIST_ARG COMMENT COMMENT_KEYWORD BIT_LITERAL
%token <bytes> NULL TRUE FALSE OFF

// Precedence dictated by mysql. But the vitess grammar is simplified.
// Some of these operators don't conflict in our situation. Nevertheless,
// it's better to have these listed in the correct order. Also, we don't
// support all operators yet.
%left <bytes> OR
%left <bytes> AND
%right <bytes> NOT '!'
%left <bytes> BETWEEN CASE WHEN THEN ELSE ELSEIF END
%left <bytes> '=' '<' '>' LE GE NE NULL_SAFE_EQUAL IS LIKE REGEXP IN
%nonassoc  UNBOUNDED // ideally should have same precedence as IDENT
%nonassoc ID NULL PARTITION RANGE ROWS GROUPS PRECEDING FOLLOWING
%left <bytes> '|'
%left <bytes> '&'
%left <bytes> SHIFT_LEFT SHIFT_RIGHT
%left <bytes> '+' '-'
%left <bytes> '*' '/' DIV '%' MOD
%left <bytes> '^'
%right <bytes> '~' UNARY
%left <bytes> COLLATE
%right <bytes> BINARY UNDERSCORE_BINARY UNDERSCORE_UTF8MB4
%right <bytes> INTERVAL
%nonassoc <bytes> '.'

// There is no need to define precedence for the JSON
// operators because the syntax is restricted enough that
// they don't cause conflicts.
%token <empty> JSON_EXTRACT_OP JSON_UNQUOTE_EXTRACT_OP

// DDL Tokens
%token <bytes> CREATE ALTER DROP RENAME ANALYZE ADD MODIFY CHANGE
%token <bytes> SCHEMA TABLE INDEX INDEXES VIEW TO IGNORE IF PRIMARY COLUMN SPATIAL FULLTEXT KEY_BLOCK_SIZE CHECK
%token <bytes> ACTION CASCADE CONSTRAINT FOREIGN NO REFERENCES RESTRICT
%token <bytes> FIRST AFTER
%token <bytes> SHOW DESCRIBE EXPLAIN DATE ESCAPE REPAIR OPTIMIZE TRUNCATE FORMAT
%token <bytes> MAXVALUE PARTITION REORGANIZE LESS THAN PROCEDURE TRIGGER TRIGGERS FUNCTION
%token <bytes> STATUS VARIABLES WARNINGS ERRORS KILL CONNECTION
%token <bytes> SEQUENCE ENABLE DISABLE
%token <bytes> EACH ROW BEFORE FOLLOWS PRECEDES DEFINER INVOKER
%token <bytes> INOUT OUT DETERMINISTIC CONTAINS READS MODIFIES SQL SECURITY TEMPORARY

// SIGNAL Tokens
%token <bytes> CLASS_ORIGIN SUBCLASS_ORIGIN MESSAGE_TEXT MYSQL_ERRNO CONSTRAINT_CATALOG CONSTRAINT_SCHEMA
%token <bytes> CONSTRAINT_NAME CATALOG_NAME SCHEMA_NAME TABLE_NAME COLUMN_NAME CURSOR_NAME SIGNAL RESIGNAL SQLSTATE

// DECLARE Tokens
%token <bytes> DECLARE CONDITION CURSOR CONTINUE EXIT UNDO HANDLER FOUND SQLWARNING SQLEXCEPTION

// Permissions Tokens
%token <bytes> USER IDENTIFIED ROLE REUSE GRANT GRANTS REVOKE NONE ATTRIBUTE RANDOM PASSWORD INITIAL AUTHENTICATION
%token <bytes> SSL X509 CIPHER ISSUER SUBJECT ACCOUNT EXPIRE NEVER DAY OPTION OPTIONAL EXCEPT ADMIN PRIVILEGES
%token <bytes> MAX_QUERIES_PER_HOUR MAX_UPDATES_PER_HOUR MAX_CONNECTIONS_PER_HOUR MAX_USER_CONNECTIONS FLUSH
%token <bytes> FAILED_LOGIN_ATTEMPTS PASSWORD_LOCK_TIME UNBOUNDED REQUIRE PROXY ROUTINE TABLESPACE CLIENT SLAVE
%token <bytes> EVENT EXECUTE FILE RELOAD REPLICATION SHUTDOWN SUPER USAGE LOGS ENGINE ERROR GENERAL HOSTS
%token <bytes> OPTIMIZER_COSTS RELAY SLOW USER_RESOURCES NO_WRITE_TO_BINLOG CHANNEL

// Transaction Tokens
%token <bytes> BEGIN START TRANSACTION COMMIT ROLLBACK SAVEPOINT WORK RELEASE

// Type Tokens
%token <bytes> BIT TINYINT SMALLINT MEDIUMINT INT INTEGER BIGINT INTNUM SERIAL
%token <bytes> REAL DOUBLE FLOAT_TYPE DECIMAL NUMERIC DEC FIXED PRECISION
%token <bytes> TIME TIMESTAMP DATETIME YEAR
%token <bytes> CHAR VARCHAR BOOL CHARACTER VARBINARY NCHAR NVARCHAR NATIONAL VARYING
%token <bytes> TEXT TINYTEXT MEDIUMTEXT LONGTEXT LONG
%token <bytes> BLOB TINYBLOB MEDIUMBLOB LONGBLOB JSON ENUM
%token <bytes> GEOMETRY POINT LINESTRING POLYGON GEOMETRYCOLLECTION MULTIPOINT MULTILINESTRING MULTIPOLYGON

// Lock tokens
%token <bytes> LOCAL LOW_PRIORITY

// Type Modifiers
%token <bytes> NULLX AUTO_INCREMENT APPROXNUM SIGNED UNSIGNED ZEROFILL

// Supported SHOW tokens
%token <bytes> COLLATION DATABASES SCHEMAS TABLES FULL PROCESSLIST COLUMNS FIELDS ENGINES PLUGINS

// SET tokens
%token <bytes> NAMES CHARSET GLOBAL SESSION ISOLATION LEVEL READ WRITE ONLY REPEATABLE COMMITTED UNCOMMITTED SERIALIZABLE
%token <bytes> ENCRYPTION

// Functions
%token <bytes> CURRENT_TIMESTAMP DATABASE CURRENT_DATE CURRENT_USER
%token <bytes> CURRENT_TIME LOCALTIME LOCALTIMESTAMP
%token <bytes> UTC_DATE UTC_TIME UTC_TIMESTAMP
%token <bytes> REPLACE
%token <bytes> CONVERT CAST
%token <bytes> SUBSTR SUBSTRING
%token <bytes> TRIM LEADING TRAILING BOTH
%token <bytes> GROUP_CONCAT SEPARATOR
%token <bytes> TIMESTAMPADD TIMESTAMPDIFF

// Window functions
%token <bytes> OVER WINDOW GROUPING GROUPS
%token <bytes> CURRENT ROWS RANGE
%token <bytes> AVG BIT_AND BIT_OR BIT_XOR COUNT JSON_ARRAYAGG JSON_OBJECTAGG MAX MIN STDDEV_POP STDDEV STD STDDEV_SAMP
%token <bytes> SUM VAR_POP VARIANCE VAR_SAMP CUME_DIST DENSE_RANK FIRST_VALUE LAG LAST_VALUE LEAD NTH_VALUE NTILE
%token <bytes> ROW_NUMBER PERCENT_RANK RANK

// Match
%token <bytes> MATCH AGAINST BOOLEAN LANGUAGE WITH QUERY EXPANSION

// MySQL reserved words that are unused by this grammar will map to this token.
%token <bytes> UNUSED ARRAY DESCRIPTION EMPTY JSON_TABLE LATERAL MEMBER RECURSIVE
%token <bytes> ACTIVE BUCKETS CLONE COMPONENT DEFINITION ENFORCED EXCLUDE FOLLOWING GEOMCOLLECTION GET_MASTER_PUBLIC_KEY HISTOGRAM HISTORY
%token <bytes> INACTIVE INVISIBLE LOCKED MASTER_COMPRESSION_ALGORITHMS MASTER_PUBLIC_KEY_PATH MASTER_TLS_CIPHERSUITES MASTER_ZSTD_COMPRESSION_LEVEL
%token <bytes> NESTED NETWORK_NAMESPACE NOWAIT NULLS OJ OLD ORDINALITY ORGANIZATION OTHERS PATH PERSIST PERSIST_ONLY PRECEDING PRIVILEGE_CHECKS_USER PROCESS
%token <bytes> REFERENCE REQUIRE_ROW_FORMAT RESOURCE RESPECT RESTART RETAIN SECONDARY SECONDARY_ENGINE SECONDARY_LOAD SECONDARY_UNLOAD SKIP SRID
%token <bytes> THREAD_PRIORITY TIES VCPU VISIBLE SYSTEM INFILE

// Generated Columns
%token <bytes> GENERATED ALWAYS STORED VIRTUAL

// TODO: categorize/organize these somehow later
%token <bytes> NVAR PASSWORD_LOCK

%type <statement> command
%type <selStmt>  create_query_expression select_statement base_select base_select_no_cte union_lhs union_rhs
%type <statement> stream_statement insert_statement update_statement delete_statement set_statement trigger_body
%type <statement> create_statement rename_statement drop_statement truncate_statement call_statement
%type <statement> trigger_begin_end_block statement_list_statement case_statement if_statement signal_statement
%type <statement> begin_end_block declare_statement resignal_statement
%type <statement> savepoint_statement rollback_savepoint_statement release_savepoint_statement
%type <statement> lock_statement unlock_statement kill_statement grant_statement revoke_statement flush_statement
%type <statements> statement_list
%type <caseStatementCases> case_statement_case_list
%type <caseStatementCase> case_statement_case
%type <ifStatementConditions> elseif_list
%type <ifStatementCondition> elseif_list_item
%type <signalInfo> signal_information_item
%type <signalInfos> signal_information_item_list
%type <signalConditionItemName> signal_information_name
%type <declareHandlerCondition> declare_handler_condition
%type <declareHandlerConditions> declare_handler_condition_list
%type <declareHandlerAction> declare_handler_action
%type <bytes> signal_condition_value
%type <str> trigger_time trigger_event
%type <statement> alter_statement alter_table_statement
%type <ddl> create_table_prefix rename_list alter_table_statement_part
%type <ddls> alter_table_statement_list
%type <statement> analyze_statement show_statement use_statement
%type <statement> describe_statement explain_statement explainable_statement
%type <statement> begin_statement commit_statement rollback_statement start_transaction_statement load_statement
%type <bytes2> comment_opt comment_list
%type <str> union_op insert_or_replace
%type <str> distinct_opt straight_join_opt cache_opt match_option separator_opt format_opt
%type <expr> like_escape_opt
%type <selectExprs> select_expression_list argument_expression_list argument_expression_list_opt
%type <selectExpr> select_expression argument_expression
%type <expr> expression naked_like group_by
%type <tableExprs> table_references cte_list
%type <with> with_clause
%type <tableExpr> table_reference table_function table_factor join_table common_table_expression
%type <simpleTableExpr> values_statement subquery_or_values
%type <subquery> subquery
%type <joinCondition> join_condition join_condition_opt on_expression_opt
%type <tableNames> table_name_list delete_table_list view_name_list
%type <str> inner_join outer_join straight_join natural_join
%type <triggerName> trigger_name
%type <tableName> table_name load_into_table_name into_table_name delete_table_name
%type <aliasedTableName> aliased_table_name aliased_table_options
%type <procedureName> procedure_name
%type <indexHints> index_hint_list
%type <expr> where_expression_opt
%type <expr> condition
%type <boolVal> boolean_value
%type <boolean> enforced_opt
%type <str> compare
%type <ins> insert_data
%type <expr> value value_expression num_val as_of_opt integral_or_value_arg integral_or_interval_expr
%type <expr> function_call_keyword function_call_nonkeyword function_call_generic function_call_conflict
%type <expr> func_datetime_precision function_call_window function_call_aggregate_with_window
%type <str> is_suffix
%type <colTuple> col_tuple
%type <exprs> expression_list group_by_list partition_by_opt
%type <values> tuple_list row_list
%type <valTuple> row_tuple tuple_or_empty
%type <expr> tuple_expression
%type <colName> column_name
%type <whens> when_expression_list
%type <when> when_expression
%type <expr> expression_opt else_expression_opt
%type <exprs> group_by_opt
%type <expr> having_opt having
%type <orderBy> order_by_opt order_list
%type <columnOrder> column_order_opt
%type <triggerOrder> trigger_order_opt
%type <order> order
%type <over> over over_opt
%type <window> window window_opt
%type <windowDef> window_definition window_spec
%type <frame> frame_opt
%type <frameExtent> frame_extent
%type <frameBound> frame_bound
%type <int> lexer_position lexer_old_position
%type <boolean> special_comment_mode
%type <str> asc_desc_opt
%type <limit> limit_opt
%type <str> lock_opt
%type <columns> ins_column_list ins_column_list_opt column_list column_list_opt
%type <partitions> opt_partition_clause partition_list
%type <assignExprs> on_dup_opt assignment_list
%type <setVarExprs> set_list transaction_chars
%type <bytes> charset_or_character_set
%type <assignExpr> assignment_expression
%type <setVarExpr> set_expression set_expression_assignment transaction_char
%type <setScope> set_scope_primary set_scope_secondary
%type <str> isolation_level
%type <bytes> for_from
%type <str> ignore_opt default_opt
%type <str> from_database_opt columns_or_fields
%type <boolean> full_opt
%type <showFilter> like_or_where_opt
%type <byt> exists_opt not_exists_opt sql_calc_found_rows_opt temp_opt
%type <str> key_type key_type_opt
%type <str> flush_type flush_type_opt
%type <empty> to_opt to_or_as as_opt column_opt describe
%type <str> definer_opt
%type <bytes> reserved_keyword non_reserved_keyword column_name_safe_reserved_keyword
%type <colIdent> sql_id reserved_sql_id col_alias as_ci_opt using_opt existing_window_name_opt
%type <colIdents> reserved_sql_id_list
%type <expr> charset_value
%type <tableIdent> table_id reserved_table_id table_alias
%type <str> charset
%type <str> show_session_or_global
%type <convertType> convert_type
%type <columnType> column_type  column_type_options
%type <columnType> int_type decimal_type numeric_type time_type char_type spatial_type
%type <sqlVal> length_opt column_comment ignore_number_opt
%type <optVal> column_default on_update
%type <str> charset_opt collate_opt
%type <boolean> default_keyword_opt
%type <charsetCollate> charset_default_opt collate_default_opt encryption_default_opt
%type <charsetCollates> creation_option creation_option_opt
%type <boolVal> stored_opt
%type <boolVal> unsigned_opt zero_fill_opt
%type <LengthScaleOption> float_length_opt decimal_length_opt
%type <boolVal> auto_increment local_opt optionally_opt
%type <colKeyOpt> column_key
%type <strs> enum_values
%type <columnDefinition> column_definition column_definition_for_create
%type <indexDefinition> index_definition
%type <constraintDefinition> constraint_definition check_constraint_definition
%type <str> index_or_key indexes_or_keys index_or_key_opt
%type <str> from_or_in show_database_opt
%type <str> name_opt
%type <str> equal_opt
%type <TableSpec> table_spec table_column_list
%type <str> table_option_list table_option table_opt_value
%type <indexInfo> index_info
%type <indexColumn> index_column
%type <indexColumns> index_column_list
%type <indexOption> index_option
%type <indexOptions> index_option_list index_option_list_opt
%type <flushOption> flush_option
%type <str> relay_logs_attribute
%type <constraintInfo> constraint_info check_constraint_info
%type <partDefs> partition_definitions
%type <partDef> partition_definition
%type <partSpec> partition_operation
%type <ReferenceAction> fk_reference_action fk_on_delete fk_on_update drop_statement_action
%type <str> pk_name_opt constraint_symbol_opt infile_opt
%type <exprs> call_param_list_opt
%type <procedureParams> proc_param_list_opt proc_param_list
%type <procedureParam> proc_param
%type <characteristics> characteristic_list_opt characteristic_list
%type <characteristic> characteristic
%type <Fields> fields_opt
%type <Lines> lines_opt
%type <EnclosedBy> enclosed_by_opt
%type <sqlVal> terminated_by_opt starting_by_opt escaped_by_opt
%type <tableAndLockTypes> lock_table_list
%type <tableAndLockType> lock_table
%type <lockType> lock_type
%type <accountName> account_name role_name
%type <accountNames> account_name_list role_name_list default_role_opt
%type <accountRenames> rename_user_list
%type <str> account_name_str user_comment_attribute
%type <accountWithAuth> account_with_auth
%type <accountsWithAuth> account_with_auth_list
%type <authentication> authentication authentication_initial
%type <tlsOptionItem> tls_option_item
%type <tlsOptionItems> tls_options tls_option_item_list
%type <accountLimitItem> account_limit_item
%type <accountLimitItems> account_limits account_limit_item_list
%type <passLockItem> pass_lock_item
%type <passLockItems> pass_lock_options pass_lock_item_list
%type <grantPrivilege> grant_privilege
%type <grantPrivileges> grant_privilege_list
%type <strs> grant_privilege_columns_opt grant_privilege_column_list
%type <grantObjectType> grant_object_type
%type <privilegeLevel> grant_privilege_level
%type <grantAssumption> grant_assumption
%type <boolean> with_grant_opt with_admin_opt

%start any_command

%%

any_command:
  command
  {
    setParseTree(yylex, $1)
  }
| command ';'
  {
    setParseTree(yylex, $1)
    statementSeen(yylex)
  }

command:
  select_statement
  {
    $$ = $1
  }
| stream_statement
| insert_statement
| update_statement
| delete_statement
| set_statement
| create_statement
| alter_statement
| rename_statement
| drop_statement
| truncate_statement
| analyze_statement
| show_statement
| use_statement
| begin_statement
| commit_statement
| rollback_statement
| explain_statement
| describe_statement
| signal_statement
| resignal_statement
| call_statement
| load_statement
| savepoint_statement
| rollback_savepoint_statement
| release_savepoint_statement
| lock_statement
| unlock_statement
| kill_statement
| grant_statement
| revoke_statement
| flush_statement
| /*empty*/
{
  setParseTree(yylex, nil)
}

load_statement:
  LOAD DATA local_opt infile_opt load_into_table_name opt_partition_clause charset_opt fields_opt lines_opt ignore_number_opt column_list_opt
  {
    $$ = &Load{Local: $3, Infile: $4, Table: $5, Partition: $6, Charset: $7, Fields: $8, Lines: $9, IgnoreNum: $10, Columns: $11}
  }

select_statement:
  base_select order_by_opt limit_opt lock_opt
  {
    $1.SetOrderBy($2)
    $1.SetLimit($3)
    $1.SetLock($4)
    $$ = $1
  }
| SELECT comment_opt cache_opt NEXT num_val for_from table_name
  {
    $$ = &Select{Comments: Comments($2), Cache: $3, SelectExprs: SelectExprs{Nextval{Expr: $5}}, From: TableExprs{&AliasedTableExpr{Expr: $7}}}
  }

stream_statement:
  STREAM comment_opt select_expression FROM table_name
  {
    $$ = &Stream{Comments: Comments($2), SelectExpr: $3, Table: $5}
  }

// base_select is an unparenthesized SELECT with no order by clause or beyond.
base_select:
  base_select_no_cte
  {
    $$ = $1
  }
| with_clause SELECT comment_opt cache_opt distinct_opt sql_calc_found_rows_opt straight_join_opt select_expression_list FROM table_references where_expression_opt group_by_opt having_opt window_opt
  {
    $$ = &Select{With: $1, Comments: Comments($3), Cache: $4, Distinct: $5, Hints: $7, SelectExprs: $8, From: $10, Where: NewWhere(WhereStr, $11), GroupBy: GroupBy($12), Having: NewWhere(HavingStr, $13), Window: $14}
    if $6 == 1 {
      $$.(*Select).CalcFoundRows = true
    }
  }
| union_lhs union_op union_rhs
  {
    $$ = &Union{Type: $2, Left: $1, Right: $3}
  }

base_select_no_cte:
  SELECT comment_opt cache_opt distinct_opt sql_calc_found_rows_opt straight_join_opt select_expression_list where_expression_opt group_by_opt having_opt window_opt
  {
    $$ = &Select{Comments: Comments($2), Cache: $3, Distinct: $4, Hints: $6, SelectExprs: $7, From: TableExprs{&AliasedTableExpr{Expr:TableName{Name: NewTableIdent("dual")}}}, Where: NewWhere(WhereStr, $8), GroupBy: GroupBy($9), Having: NewWhere(HavingStr, $10), Window: $11}
    if $5 == 1 {
      $$.(*Select).CalcFoundRows = true
    }
  }
| SELECT comment_opt cache_opt distinct_opt sql_calc_found_rows_opt straight_join_opt select_expression_list FROM table_references where_expression_opt group_by_opt having_opt window_opt
  {
    $$ = &Select{Comments: Comments($2), Cache: $3, Distinct: $4, Hints: $6, SelectExprs: $7, From: $9, Where: NewWhere(WhereStr, $10), GroupBy: GroupBy($11), Having: NewWhere(HavingStr, $12), Window: $13}
    if $5 == 1 {
      $$.(*Select).CalcFoundRows = true
    }
  }

with_clause:
  WITH cte_list
  {
   $$ = &With{Ctes: $2, Recursive: false}
  }
| WITH RECURSIVE cte_list
  {
    $$ = &With{Ctes: $3, Recursive: true}
  }

cte_list:
  common_table_expression
  {
    $$ = TableExprs{$1}
  }
| cte_list ',' common_table_expression
  {
    $$ = append($1, $3)
  }

common_table_expression:
  table_alias ins_column_list_opt AS subquery_or_values
  {
    $$ = &CommonTableExpr{&AliasedTableExpr{Expr:$4, As: $1}, $2}
  }

union_lhs:
  base_select
  {
    $$ = $1
  }
| openb select_statement closeb
  {
    $$ = &ParenSelect{Select: $2}
  }

union_rhs:
  base_select_no_cte
  {
    $$ = $1
  }
| openb select_statement closeb
  {
    $$ = &ParenSelect{Select: $2}
  }

insert_statement:
  insert_or_replace comment_opt ignore_opt into_table_name opt_partition_clause insert_data on_dup_opt
  {
    // insert_data returns a *Insert pre-filled with Columns & Values
    ins := $6
    ins.Action = $1
    ins.Comments = $2
    ins.Ignore = $3
    ins.Table = $4
    ins.Partitions = $5
    ins.OnDup = OnDup($7)
    $$ = ins
  }
| insert_or_replace comment_opt ignore_opt into_table_name opt_partition_clause SET assignment_list on_dup_opt
  {
    cols := make(Columns, 0, len($7))
    vals := make(ValTuple, 0, len($8))
    for _, updateList := range $7 {
      cols = append(cols, updateList.Name.Name)
      vals = append(vals, updateList.Expr)
    }
    $$ = &Insert{Action: $1, Comments: Comments($2), Ignore: $3, Table: $4, Partitions: $5, Columns: cols, Rows: Values{vals}, OnDup: OnDup($8)}
  }

insert_or_replace:
  INSERT
  {
    $$ = InsertStr
  }
| REPLACE
  {
    $$ = ReplaceStr
  }

update_statement:
  UPDATE comment_opt ignore_opt table_references SET assignment_list where_expression_opt order_by_opt limit_opt
  {
    $$ = &Update{Comments: Comments($2), Ignore: $3, TableExprs: $4, Exprs: $6, Where: NewWhere(WhereStr, $7), OrderBy: $8, Limit: $9}
  }

delete_statement:
  DELETE comment_opt FROM table_name opt_partition_clause where_expression_opt order_by_opt limit_opt
  {
    $$ = &Delete{Comments: Comments($2), TableExprs:  TableExprs{&AliasedTableExpr{Expr:$4}}, Partitions: $5, Where: NewWhere(WhereStr, $6), OrderBy: $7, Limit: $8}
  }
| DELETE comment_opt FROM table_name_list USING table_references where_expression_opt
  {
    $$ = &Delete{Comments: Comments($2), Targets: $4, TableExprs: $6, Where: NewWhere(WhereStr, $7)}
  }
| DELETE comment_opt table_name_list from_or_using table_references where_expression_opt
  {
    $$ = &Delete{Comments: Comments($2), Targets: $3, TableExprs: $5, Where: NewWhere(WhereStr, $6)}
  }
| DELETE comment_opt delete_table_list from_or_using table_references where_expression_opt
  {
    $$ = &Delete{Comments: Comments($2), Targets: $3, TableExprs: $5, Where: NewWhere(WhereStr, $6)}
  }

from_or_using:
  FROM {}
| USING {}

view_name_list:
  table_name
  {
    $$ = TableNames{$1.ToViewName()}
  }
| view_name_list ',' table_name
  {
    $$ = append($$, $3.ToViewName())
  }

table_name_list:
  table_name
  {
    $$ = TableNames{$1}
  }
| table_name_list ',' table_name
  {
    $$ = append($$, $3)
  }

delete_table_list:
  delete_table_name
  {
    $$ = TableNames{$1}
  }
| delete_table_list ',' delete_table_name
  {
    $$ = append($$, $3)
  }

opt_partition_clause:
  {
    $$ = nil
  }
| PARTITION openb partition_list closeb
  {
  $$ = $3
  }

set_statement:
  SET comment_opt set_list
  {
    $$ = &Set{Comments: Comments($2), Exprs: $3}
  }
| SET comment_opt TRANSACTION transaction_chars
  {
    for i := 0; i < len($4); i++ {
      $4[i].Scope = SetScope_None
    }
    $$ = &Set{Comments: Comments($2), Exprs: $4}
  }
| SET comment_opt set_scope_primary TRANSACTION transaction_chars
  {
    for i := 0; i < len($5); i++ {
      $5[i].Scope = $3
    }
    $$ = &Set{Comments: Comments($2), Exprs: $5}
  }

transaction_chars:
  transaction_char
  {
    $$ = SetVarExprs{$1}
  }
| transaction_chars ',' transaction_char
  {
    $$ = append($$, $3)
  }

transaction_char:
  ISOLATION LEVEL isolation_level
  {
    $$ = &SetVarExpr{Name: NewColName(TransactionStr), Expr: NewStrVal([]byte($3))}
  }
| READ WRITE
  {
    $$ = &SetVarExpr{Name: NewColName(TransactionStr), Expr: NewStrVal([]byte(TxReadWrite))}
  }
| READ ONLY
  {
    $$ = &SetVarExpr{Name: NewColName(TransactionStr), Expr: NewStrVal([]byte(TxReadOnly))}
  }

isolation_level:
  REPEATABLE READ
  {
    $$ = IsolationLevelRepeatableRead
  }
| READ COMMITTED
  {
    $$ = IsolationLevelReadCommitted
  }
| READ UNCOMMITTED
  {
    $$ = IsolationLevelReadUncommitted
  }
| SERIALIZABLE
  {
    $$ = IsolationLevelSerializable
  }

lexer_position:
  {
    $$ = yyPosition(yylex)
  }

lexer_old_position:
  {
    $$ = yyOldPosition(yylex)
  }

special_comment_mode:
  {
    $$ = yySpecialCommentMode(yylex)
  }

create_statement:
  create_table_prefix table_spec
  {
    $1.TableSpec = $2
    if len($1.TableSpec.Constraints) > 0 {
      $1.ConstraintAction = AddStr
    }
    $$ = $1
  }
  // TODO: Allow for table specs to be parsed here
| create_table_prefix as_opt create_query_expression
  {
    $1.OptSelect = &OptSelect{Select: $3}
    $$ = $1
  }
| create_table_prefix LIKE table_name
  {
    $1.OptLike = &OptLike{LikeTable: $3}
    $$ = $1
  }
| CREATE key_type_opt INDEX sql_id using_opt ON table_name '(' index_column_list ')' index_option_list_opt
  {
    $$ = &DDL{Action: AlterStr, Table: $7, IndexSpec: &IndexSpec{Action: CreateStr, ToName: $4, Using: $5, Type: $2, Columns: $9, Options: $11}}
  }
| CREATE VIEW table_name AS lexer_position special_comment_mode select_statement lexer_position
  {
    $$ = &DDL{Action: CreateStr, View: $3.ToViewName(), ViewExpr: $7, SpecialCommentMode: $6, SubStatementPositionStart: $5, SubStatementPositionEnd: $8 - 1}
  }
| CREATE OR REPLACE VIEW table_name AS lexer_position special_comment_mode select_statement lexer_position
  {
    $$ = &DDL{Action: CreateStr, View: $5.ToViewName(), ViewExpr: $9,  SpecialCommentMode: $8, SubStatementPositionStart: $7, SubStatementPositionEnd: $10 - 1, OrReplace: true}
  }
| CREATE DATABASE not_exists_opt ID creation_option_opt
  {
    var ne bool
    if $3 != 0 {
      ne = true
    }
    $$ = &DBDDL{Action: CreateStr, DBName: string($4), IfNotExists: ne, CharsetCollate: $5}
  }
| CREATE SCHEMA not_exists_opt ID creation_option_opt
  {
    var ne bool
    if $3 != 0 {
      ne = true
    }
    $$ = &DBDDL{Action: CreateStr, DBName: string($4), IfNotExists: ne, CharsetCollate: $5}
  }
| CREATE definer_opt TRIGGER trigger_name trigger_time trigger_event ON table_name FOR EACH ROW trigger_order_opt lexer_position special_comment_mode trigger_body lexer_position
  {
    $$ = &DDL{Action: CreateStr, Table: $8, TriggerSpec: &TriggerSpec{TrigName: $4, Time: $5, Event: $6, Order: $12, Body: $15}, SpecialCommentMode: $14, SubStatementPositionStart: $13, SubStatementPositionEnd: $16 - 1}
  }
| CREATE definer_opt PROCEDURE procedure_name '(' proc_param_list_opt ')' characteristic_list_opt lexer_old_position special_comment_mode statement_list_statement lexer_position
  {
    $$ = &DDL{Action: CreateStr, ProcedureSpec: &ProcedureSpec{ProcName: $4, Definer: $2, Params: $6, Characteristics: $8, Body: $11}, SpecialCommentMode: $10, SubStatementPositionStart: $9, SubStatementPositionEnd: $12 - 1}
  }
| CREATE USER not_exists_opt account_with_auth_list default_role_opt tls_options account_limits pass_lock_options user_comment_attribute
  {
    var notExists bool
    if $3 != 0 {
      notExists = true
    }
    tlsOptions, err := NewTLSOptions($6)
    if err != nil {
      yylex.Error(err.Error())
      return 1
    }
    accountLimits, err := NewAccountLimits($7)
    if err != nil {
      yylex.Error(err.Error())
      return 1
    }
    passwordOptions, locked := NewPasswordOptionsWithLock($8)
    $$ = &CreateUser{IfNotExists: notExists, Users: $4, DefaultRoles: $5, TLSOptions: tlsOptions, AccountLimits: accountLimits, PasswordOptions: passwordOptions, Locked: locked, Attribute: $9}
  }
| CREATE ROLE not_exists_opt role_name_list
  {
    var notExists bool
    if $3 != 0 {
      notExists = true
    }
    $$ = &CreateRole{IfNotExists: notExists, Roles: $4}
  }

default_role_opt:
  {
    $$ = nil
  }
| DEFAULT ROLE role_name_list
  {
    $$ = $3
  }

tls_options:
  {
    $$ = nil
  }
| REQUIRE NONE
  {
    $$ = nil
  }
| REQUIRE tls_option_item_list
  {
    $$ = $2
  }

tls_option_item_list:
  tls_option_item
  {
    $$ = []TLSOptionItem{$1}
  }
| tls_option_item_list AND tls_option_item
  {
    $$ = append($1, $3)
  }

tls_option_item:
  SSL
  {
    $$ = TLSOptionItem{TLSOptionItemType: TLSOptionItemType_SSL, ItemData: ""}
  }
| X509
  {
    $$ = TLSOptionItem{TLSOptionItemType: TLSOptionItemType_X509, ItemData: ""}
  }
| CIPHER STRING
  {
    $$ = TLSOptionItem{TLSOptionItemType: TLSOptionItemType_Cipher, ItemData: string($2)}
  }
| ISSUER STRING
  {
    $$ = TLSOptionItem{TLSOptionItemType: TLSOptionItemType_Issuer, ItemData: string($2)}
  }
| SUBJECT STRING
  {
    $$ = TLSOptionItem{TLSOptionItemType: TLSOptionItemType_Subject, ItemData: string($2)}
  }

account_limits:
  {
    $$ = nil
  }
| WITH account_limit_item_list
  {
    $$ = $2
  }

account_limit_item_list:
  account_limit_item
  {
    $$ = []AccountLimitItem{$1}
  }
| account_limit_item_list account_limit_item
  {
    $$ = append($1, $2)
  }

account_limit_item:
  MAX_QUERIES_PER_HOUR INTEGRAL
  {
    $$ = AccountLimitItem{AccountLimitItemType: AccountLimitItemType_Queries_PH, Count: NewIntVal($2)}
  }
| MAX_UPDATES_PER_HOUR INTEGRAL
  {
    $$ = AccountLimitItem{AccountLimitItemType: AccountLimitItemType_Updates_PH, Count: NewIntVal($2)}
  }
| MAX_CONNECTIONS_PER_HOUR INTEGRAL
  {
    $$ = AccountLimitItem{AccountLimitItemType: AccountLimitItemType_Connections_PH, Count: NewIntVal($2)}
  }
| MAX_USER_CONNECTIONS INTEGRAL
  {
    $$ = AccountLimitItem{AccountLimitItemType: AccountLimitItemType_Connections, Count: NewIntVal($2)}
  }

pass_lock_options:
  {
    $$ = nil
  }
| pass_lock_item_list
  {
    $$ = $1
  }

pass_lock_item_list:
  pass_lock_item
  {
    $$ = []PassLockItem{$1}
  }
| pass_lock_item_list pass_lock_item
  {
    $$ = append($1, $2)
  }

pass_lock_item:
  PASSWORD EXPIRE DEFAULT
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassExpireDefault, Value: nil}
  }
| PASSWORD EXPIRE NEVER
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassExpireNever, Value: nil}
  }
| PASSWORD EXPIRE INTERVAL INTEGRAL DAY
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassExpireInterval, Value: NewIntVal($4)}
  }
| PASSWORD HISTORY DEFAULT
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassHistory, Value: nil}
  }
| PASSWORD HISTORY INTEGRAL
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassHistory, Value: NewIntVal($3)}
  }
| PASSWORD REUSE INTERVAL DEFAULT
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassReuseInterval, Value: nil}
  }
| PASSWORD REUSE INTERVAL INTEGRAL DAY
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassReuseInterval, Value: NewIntVal($4)}
  }
| PASSWORD REQUIRE CURRENT DEFAULT
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassReqCurrentDefault, Value: nil}
  }
| PASSWORD REQUIRE CURRENT OPTIONAL
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassReqCurrentOptional, Value: nil}
  }
| FAILED_LOGIN_ATTEMPTS INTEGRAL
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassFailedLogins, Value: NewIntVal($2)}
  }
| PASSWORD_LOCK_TIME INTEGRAL
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassLockTime, Value: NewIntVal($2)}
  }
| PASSWORD_LOCK_TIME UNBOUNDED
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_PassLockTime, Value: nil}
  }
| ACCOUNT LOCK
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_AccountLock, Value: nil}
  }
| ACCOUNT UNLOCK
  {
    $$ = PassLockItem{PassLockItemType: PassLockItemType_AccountUnlock, Value: nil}
  }

user_comment_attribute:
  {
    $$ = ""
  }
| COMMENT_KEYWORD STRING
  {
    comment := string($2)
    $$ = `{"comment": "`+escapeDoubleQuotes(comment)+`"}`
  }
| ATTRIBUTE STRING
  {
    $$ = string($2)
  }

grant_statement:
  GRANT ALL ON grant_object_type grant_privilege_level TO account_name_list with_grant_opt grant_assumption
  {
    allPriv := []Privilege{Privilege{Type: PrivilegeType_All, Columns: nil}}
    $$ = &GrantPrivilege{Privileges: allPriv, ObjectType: $4, PrivilegeLevel: $5, To: $7, WithGrantOption: $8, As: $9}
  }
| GRANT grant_privilege_list ON grant_object_type grant_privilege_level TO account_name_list with_grant_opt grant_assumption
  {
    $$ = &GrantPrivilege{Privileges: $2, ObjectType: $4, PrivilegeLevel: $5, To: $7, WithGrantOption: $8, As: $9}
  }
| GRANT role_name_list TO account_name_list with_admin_opt
  {
    $$ = &GrantRole{Roles: $2, To: $4, WithAdminOption: $5}
  }
| GRANT PROXY ON account_name TO account_name_list with_grant_opt
  {
    $$ = &GrantProxy{On: $4, To: $6, WithGrantOption: $7}
  }

revoke_statement:
  REVOKE ALL ON grant_object_type grant_privilege_level FROM account_name_list
  {
    allPriv := []Privilege{Privilege{Type: PrivilegeType_All, Columns: nil}}
    $$ = &RevokePrivilege{Privileges: allPriv, ObjectType: $4, PrivilegeLevel: $5, From: $7}
  }
| REVOKE grant_privilege_list ON grant_object_type grant_privilege_level FROM account_name_list
  {
    $$ = &RevokePrivilege{Privileges: $2, ObjectType: $4, PrivilegeLevel: $5, From: $7}
  }
| REVOKE ALL ',' GRANT OPTION FROM account_name_list
  {
    $$ = &RevokeAllPrivileges{From: $7}
  }
| REVOKE ALL PRIVILEGES ',' GRANT OPTION FROM account_name_list
  {
    $$ = &RevokeAllPrivileges{From: $8}
  }
| REVOKE role_name_list FROM account_name_list
  {
    $$ = &RevokeRole{Roles: $2, From: $4}
  }
| REVOKE PROXY ON account_name FROM account_name_list
  {
    $$ = &RevokeProxy{On: $4, From: $6}
  }

grant_privilege:
  ALTER grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Alter, Columns: $2}
  }
| ALTER ROUTINE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_AlterRoutine, Columns: $3}
  }
| CREATE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Create, Columns: $2}
  }
| CREATE ROLE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateRole, Columns: $3}
  }
| CREATE ROUTINE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateRoutine, Columns: $3}
  }
| CREATE TABLESPACE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateTablespace, Columns: $3}
  }
| CREATE TEMPORARY TABLES grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateTemporaryTables, Columns: $4}
  }
| CREATE USER grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateUser, Columns: $3}
  }
| CREATE VIEW grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_CreateView, Columns: $3}
  }
| DELETE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Delete, Columns: $2}
  }
| DROP grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Drop, Columns: $2}
  }
| DROP ROLE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_DropRole, Columns: $3}
  }
| EVENT grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Event, Columns: $2}
  }
| EXECUTE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Execute, Columns: $2}
  }
| FILE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_File, Columns: $2}
  }
| INDEX grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Index, Columns: $2}
  }
| INSERT grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Insert, Columns: $2}
  }
| LOCK TABLES grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_LockTables, Columns: $3}
  }
| PROCESS grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Process, Columns: $2}
  }
| REFERENCES grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_References, Columns: $2}
  }
| RELOAD grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Reload, Columns: $2}
  }
| REPLICATION CLIENT grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_ReplicationClient, Columns: $3}
  }
| REPLICATION SLAVE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_ReplicationSlave, Columns: $3}
  }
| SELECT grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Select, Columns: $2}
  }
| SHOW DATABASES grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_ShowDatabases, Columns: $3}
  }
| SHOW VIEW grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_ShowView, Columns: $3}
  }
| SHUTDOWN grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Shutdown, Columns: $2}
  }
| SUPER grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Super, Columns: $2}
  }
| TRIGGER grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Trigger, Columns: $2}
  }
| UPDATE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Update, Columns: $2}
  }
| USAGE grant_privilege_columns_opt
  {
    $$ = Privilege{Type: PrivilegeType_Usage, Columns: $2}
  }

grant_privilege_list:
  grant_privilege
  {
    $$ = []Privilege{$1}
  }
| grant_privilege_list ',' grant_privilege
  {
    $$ = append($1, $3)
  }

grant_privilege_columns_opt:
  {
    $$ = nil
  }
| '(' grant_privilege_column_list ')'
  {
    $$ = $2
  }

grant_privilege_column_list:
  sql_id
  {
    $$ = []string{$1.String()}
  }
| grant_privilege_column_list ',' sql_id
  {
    $$ = append($1, $3.String())
  }

grant_object_type:
  {
    $$ = GrantObjectType_Any
  }
| TABLE
  {
    $$ = GrantObjectType_Table
  }
| FUNCTION
  {
    $$ = GrantObjectType_Function
  }
| PROCEDURE
  {
    $$ = GrantObjectType_Procedure
  }

grant_privilege_level:
  '*'
  {
    $$ = PrivilegeLevel{Database: "", TableRoutine: "*"}
  }
| '*' '.' '*'
  {
    $$ = PrivilegeLevel{Database: "*", TableRoutine: "*"}
  }
| sql_id
  {
    $$ = PrivilegeLevel{Database: "", TableRoutine: $1.String()}
  }
| sql_id '.' '*'
  {
    $$ = PrivilegeLevel{Database: $1.String(), TableRoutine: "*"}
  }
| sql_id '.' sql_id
  {
    $$ = PrivilegeLevel{Database: $1.String(), TableRoutine: $3.String()}
  }

grant_assumption:
  {
    $$ = nil
  }
| AS account_name
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_Default, User: $2, Roles: nil}
  }
| AS account_name WITH ROLE DEFAULT
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_Default, User: $2, Roles: nil}
  }
| AS account_name WITH ROLE NONE
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_None, User: $2, Roles: nil}
  }
| AS account_name WITH ROLE ALL
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_All, User: $2, Roles: nil}
  }
| AS account_name WITH ROLE ALL EXCEPT role_name_list
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_AllExcept, User: $2, Roles: $7}
  }
| AS account_name WITH ROLE role_name_list
  {
    $$ = &GrantUserAssumption{Type: GrantUserAssumptionType_Roles, User: $2, Roles: $5}
  }

with_grant_opt:
  {
    $$ = false
  }
| WITH GRANT OPTION
  {
    $$ = true
  }

with_admin_opt:
  {
    $$ = false
  }
| WITH ADMIN OPTION
  {
    $$ = true
  }

// TODO: Implement IGNORE, REPLACE, VALUES, and TABLE
create_query_expression:
  base_select_no_cte order_by_opt limit_opt lock_opt
  {
    $1.SetOrderBy($2)
    $1.SetLimit($3)
    $1.SetLock($4)
    $$ = $1
  }

proc_param_list_opt:
  {
    $$ = nil
  }
| proc_param_list
  {
    $$ = $1
  }

proc_param_list:
  proc_param
  {
    $$ = []ProcedureParam{$1}
  }
| proc_param_list ',' proc_param
  {
    $$ = append($$, $3)
  }

proc_param:
  ID column_type
  {
    $$ = ProcedureParam{Direction: ProcedureParamDirection_In, Name: string($1), Type: $2}
  }
| IN ID column_type
  {
    $$ = ProcedureParam{Direction: ProcedureParamDirection_In, Name: string($2), Type: $3}
  }
| INOUT ID column_type
  {
    $$ = ProcedureParam{Direction: ProcedureParamDirection_Inout, Name: string($2), Type: $3}
  }
| OUT ID column_type
  {
    $$ = ProcedureParam{Direction: ProcedureParamDirection_Out, Name: string($2), Type: $3}
  }

characteristic_list_opt:
  {
    $$ = nil
  }
| characteristic_list
  {
    $$ = $1
  }

characteristic_list:
  characteristic
  {
    $$ = []Characteristic{$1}
  }
| characteristic_list characteristic
  {
    $$ = append($$, $2)
  }

characteristic:
  COMMENT_KEYWORD STRING
  {
    $$ = Characteristic{Type: CharacteristicValue_Comment, Comment: string($2)}
  }
| LANGUAGE SQL
  {
    $$ = Characteristic{Type: CharacteristicValue_LanguageSql}
  }
| NOT DETERMINISTIC
  {
    $$ = Characteristic{Type: CharacteristicValue_NotDeterministic}
  }
| DETERMINISTIC
  {
    $$ = Characteristic{Type: CharacteristicValue_Deterministic}
  }
| CONTAINS SQL
  {
    $$ = Characteristic{Type: CharacteristicValue_ContainsSql}
  }
| NO SQL
  {
    $$ = Characteristic{Type: CharacteristicValue_NoSql}
  }
| READS SQL DATA
  {
    $$ = Characteristic{Type: CharacteristicValue_ReadsSqlData}
  }
| MODIFIES SQL DATA
  {
    $$ = Characteristic{Type: CharacteristicValue_ModifiesSqlData}
  }
| SQL SECURITY DEFINER
  {
    $$ = Characteristic{Type: CharacteristicValue_SqlSecurityDefiner}
  }
| SQL SECURITY INVOKER
  {
    $$ = Characteristic{Type: CharacteristicValue_SqlSecurityInvoker}
  }

begin_end_block:
  BEGIN statement_list ';' END
  {
    $$ = &BeginEndBlock{Statements: $2}
  }

definer_opt:
  {
    $$ = ""
  }
| DEFINER '=' ID
  {
    $$ = string($3)
  }

account_name_str:
  STRING
  {
    $$ = string($1)
  }
| ID
  {
    $$ = string($1)
  }
| non_reserved_keyword
  {
    $$ = string($1)
  }

account_name:
  account_name_str '@' account_name_str
  {
    anyHost := false
    if $3 == "%" {
      anyHost = true
    }
    $$ = AccountName{Name: $1, Host: $3, AnyHost: anyHost}
  }
| account_name_str '@'
  {
    $$ = AccountName{Name: $1, Host: "", AnyHost: false}
  }
| account_name_str
  {
    $$ = AccountName{Name: $1, Host: "", AnyHost: true}
  }

account_name_list:
  account_name
  {
    $$ = []AccountName{$1}
  }
| account_name_list ',' account_name
  {
    $$ = append($1, $3)
  }

role_name:
  account_name_str '@' account_name_str
  {
    if len($1) == 0 {
      yylex.Error("the anonymous user is not a valid role name")
      return 1
    }
    $$ = AccountName{Name: $1, Host: $3, AnyHost: false}
  }
| account_name_str '@'
  {
    if len($1) == 0 {
      yylex.Error("the anonymous user is not a valid role name")
      return 1
    }
    $$ = AccountName{Name: $1, Host: "", AnyHost: false}
  }
| account_name_str
  {
    if len($1) == 0 {
      yylex.Error("the anonymous user is not a valid role name")
      return 1
    }
    $$ = AccountName{Name: $1, Host: "", AnyHost: true}
  }

role_name_list:
  role_name
  {
    $$ = []AccountName{$1}
  }
| role_name_list ',' role_name
  {
    $$ = append($1, $3)
  }

account_with_auth:
  account_name
  {
    $$ = AccountWithAuth{AccountName: $1}
  }
| account_name authentication
  {
    $$ = AccountWithAuth{AccountName: $1, Auth1: $2}
  }
| account_name authentication INITIAL AUTHENTICATION authentication_initial
  {
    $$ = AccountWithAuth{AccountName: $1, Auth1: $2, AuthInitial: $5}
  }
| account_name authentication AND authentication
  {
    $$ = AccountWithAuth{AccountName: $1, Auth1: $2, Auth2: $4}
  }
| account_name authentication AND authentication AND authentication
  {
    $$ = AccountWithAuth{AccountName: $1, Auth1: $2, Auth2: $4, Auth3: $6}
  }

authentication:
  IDENTIFIED BY RANDOM PASSWORD
  {
    $$ = &Authentication{RandomPassword: true}
  }
| IDENTIFIED BY STRING
  {
    $$ = &Authentication{Password: string($3)}
  }
| IDENTIFIED WITH ID
  {
    $$ = &Authentication{Plugin: string($3)}
  }
| IDENTIFIED WITH ID BY RANDOM PASSWORD
  {
    $$ = &Authentication{Plugin: string($3), RandomPassword: true}
  }
| IDENTIFIED WITH ID BY STRING
  {
    $$ = &Authentication{Plugin: string($3), Password: string($5)}
  }
| IDENTIFIED WITH ID AS STRING
  {
    $$ = &Authentication{Plugin: string($3), Identity: string($5)}
  }

authentication_initial:
  IDENTIFIED BY RANDOM PASSWORD
  {
    $$ = &Authentication{RandomPassword: true}
  }
| IDENTIFIED BY STRING
  {
    $$ = &Authentication{Password: string($3)}
  }
| IDENTIFIED WITH ID AS STRING
  {
    $$ = &Authentication{Plugin: string($3), Identity: string($5)}
  }

account_with_auth_list:
  account_with_auth
  {
    $$ = []AccountWithAuth{$1}
  }
| account_with_auth_list ',' account_with_auth
  {
    $$ = append($1, $3)
  }

trigger_time:
  BEFORE
  {
    $$ = BeforeStr
  }
| AFTER
  {
    $$ = AfterStr
  }

trigger_event:
  INSERT
  {
    $$ = InsertStr
  }
| UPDATE
  {
    $$ = UpdateStr
  }
| DELETE
  {
    $$ = DeleteStr
  }

trigger_order_opt:
  {
    $$ = nil
  }
| FOLLOWS ID
  {
    $$ = &TriggerOrder{PrecedesOrFollows: FollowsStr, OtherTriggerName: string($2)}
  }
| PRECEDES ID
  {
    $$ = &TriggerOrder{PrecedesOrFollows: PrecedesStr, OtherTriggerName: string($2)}
  }

trigger_body:
  trigger_begin_end_block
  {
    $$ = $1
  }
| set_statement
| insert_statement
| update_statement
| delete_statement

trigger_begin_end_block:
  BEGIN statement_list ';' END
  {
    $$ = &BeginEndBlock{Statements: $2}
  }

case_statement:
  CASE expression case_statement_case_list END CASE
  {
    $$ = &CaseStatement{Expr: $2, Cases: $3}
  }
| CASE expression case_statement_case_list ELSE statement_list ';' END CASE
  {
    $$ = &CaseStatement{Expr: $2, Cases: $3, Else: $5}
  }

case_statement_case_list:
  case_statement_case
  {
    $$ = []CaseStatementCase{$1}
  }
| case_statement_case_list case_statement_case
  {
    $$ = append($$, $2)
  }

case_statement_case:
  WHEN expression THEN statement_list ';'
  {
    $$ = CaseStatementCase{Case: $2, Statements: $4}
  }

if_statement:
  IF expression THEN statement_list ';' END IF
  {
    conds := []IfStatementCondition{IfStatementCondition{Expr: $2, Statements: $4}}
    $$ = &IfStatement{Conditions: conds}
  }
| IF expression THEN statement_list ';' ELSE statement_list ';' END IF
  {
    conds := []IfStatementCondition{IfStatementCondition{Expr: $2, Statements: $4}}
    $$ = &IfStatement{Conditions: conds, Else: $7}
  }
| IF expression THEN statement_list ';' elseif_list END IF
  {
    conds := $6
    conds = append([]IfStatementCondition{IfStatementCondition{Expr: $2, Statements: $4}}, conds...)
    $$ = &IfStatement{Conditions: conds}
  }
| IF expression THEN statement_list ';' elseif_list ELSE statement_list ';' END IF
  {
    conds := $6
    conds = append([]IfStatementCondition{IfStatementCondition{Expr: $2, Statements: $4}}, conds...)
    $$ = &IfStatement{Conditions: conds, Else: $8}
  }

elseif_list:
  elseif_list_item
  {
    $$ = []IfStatementCondition{$1}
  }
| elseif_list elseif_list_item
  {
    $$ = append($$, $2)
  }

elseif_list_item:
  ELSEIF expression THEN statement_list ';'
  {
    $$ = IfStatementCondition{Expr: $2, Statements: $4}
  }

declare_statement:
  DECLARE ID CONDITION FOR signal_condition_value
  {
    $$ = &Declare{Condition: &DeclareCondition{Name: string($2), SqlStateValue: string($5)}}
  }
| DECLARE ID CONDITION FOR INTEGRAL
  {
    $$ = &Declare{Condition: &DeclareCondition{Name: string($2), MysqlErrorCode: NewIntVal($5)}}
  }
| DECLARE ID CURSOR FOR select_statement
  {
    $$ = &Declare{Cursor: &DeclareCursor{Name: string($2), SelectStmt: $5}}
  }
| DECLARE declare_handler_action HANDLER FOR declare_handler_condition_list statement_list_statement
  {
    $$ = &Declare{Handler: &DeclareHandler{Action: $2, ConditionValues: $5, Statement: $6}}
  }
| DECLARE reserved_sql_id_list column_type
  {
    $$ = &Declare{Variables: &DeclareVariables{Names: $2, VarType: $3}}
  }
| DECLARE reserved_sql_id_list column_type DEFAULT value_expression
  {
    $3.Default = $5
    $$ = &Declare{Variables: &DeclareVariables{Names: $2, VarType: $3}}
  }

declare_handler_action:
  CONTINUE
  {
    $$ = DeclareHandlerAction_Continue
  }
| EXIT
  {
    $$ = DeclareHandlerAction_Exit
  }
| UNDO
  {
    $$ = DeclareHandlerAction_Undo
  }

declare_handler_condition_list:
  declare_handler_condition
  {
    $$ = []DeclareHandlerCondition{$1}
  }
| declare_handler_condition_list ',' declare_handler_condition
  {
    $$ = append($$, $3)
  }

declare_handler_condition:
  INTEGRAL
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_MysqlErrorCode, MysqlErrorCode: NewIntVal($1)}
  }
| signal_condition_value
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_SqlState, String: string($1)}
  }
| SQLWARNING
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_SqlWarning}
  }
| NOT FOUND
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_NotFound}
  }
| SQLEXCEPTION
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_SqlException}
  }
| ID
  {
    $$ = DeclareHandlerCondition{ValueType: DeclareHandlerCondition_ConditionName, String: string($1)}
  }

signal_statement:
  SIGNAL signal_condition_value
  {
    $$ = &Signal{SqlStateValue: string($2)}
  }
| SIGNAL signal_condition_value SET signal_information_item_list
  {
    $$ = &Signal{SqlStateValue: string($2), Info: $4}
  }
| SIGNAL ID
  {
    $$ = &Signal{ConditionName: string($2)}
  }
| SIGNAL ID SET signal_information_item_list
  {
    $$ = &Signal{ConditionName: string($2), Info: $4}
  }

signal_condition_value:
  SQLSTATE STRING
  {
    $$ = $2
  }
| SQLSTATE VALUE STRING
  {
    $$ = $3
  }

signal_information_item_list:
  signal_information_item
  {
    $$ = []SignalInfo{$1}
  }
| signal_information_item_list ',' signal_information_item
  {
    $$ = append($$, $3)
  }

signal_information_item:
  signal_information_name '=' value
  {
    $$ = SignalInfo{ConditionItemName: $1, Value: $3.(*SQLVal)}
  }

signal_information_name:
  CLASS_ORIGIN
  {
    $$ = SignalConditionItemName_ClassOrigin
  }
| SUBCLASS_ORIGIN
  {
    $$ = SignalConditionItemName_SubclassOrigin
  }
| MESSAGE_TEXT
  {
    $$ = SignalConditionItemName_MessageText
  }
| MYSQL_ERRNO
  {
    $$ = SignalConditionItemName_MysqlErrno
  }
| CONSTRAINT_CATALOG
  {
    $$ = SignalConditionItemName_ConstraintCatalog
  }
| CONSTRAINT_SCHEMA
  {
    $$ = SignalConditionItemName_ConstraintSchema
  }
| CONSTRAINT_NAME
  {
    $$ = SignalConditionItemName_ConstraintName
  }
| CATALOG_NAME
  {
    $$ = SignalConditionItemName_CatalogName
  }
| SCHEMA_NAME
  {
    $$ = SignalConditionItemName_SchemaName
  }
| TABLE_NAME
  {
    $$ = SignalConditionItemName_TableName
  }
| COLUMN_NAME
  {
    $$ = SignalConditionItemName_ColumnName
  }
| CURSOR_NAME
  {
    $$ = SignalConditionItemName_CursorName
  }

resignal_statement:
  RESIGNAL
  {
    $$ = &Resignal{}
  }
| RESIGNAL signal_condition_value
  {
    $$ = &Resignal{Signal{SqlStateValue: string($2)}}
  }
| RESIGNAL signal_condition_value SET signal_information_item_list
  {
    $$ = &Resignal{Signal{SqlStateValue: string($2), Info: $4}}
  }
| RESIGNAL SET signal_information_item_list
  {
    $$ = &Resignal{Signal{Info: $3}}
  }
| RESIGNAL ID
  {
    $$ = &Resignal{Signal{ConditionName: string($2)}}
  }
| RESIGNAL ID SET signal_information_item_list
  {
    $$ = &Resignal{Signal{ConditionName: string($2), Info: $4}}
  }

call_statement:
  CALL ID call_param_list_opt
  {
    $$ = &Call{FuncName: string($2), Params: $3}
  }

call_param_list_opt:
  {
    $$ = nil
  }
| '(' ')'
  {
    $$ = nil
  }
| '(' expression_list ')'
  {
    $$ = $2
  }

statement_list:
  statement_list_statement
  {
    $$ = Statements{$1}
  }
| statement_list ';' statement_list_statement
  {
    $$ = append($$, $3)
  }

statement_list_statement:
  select_statement
  {
    $$ = $1
  }
| insert_statement
| update_statement
| delete_statement
| set_statement
| create_statement
| alter_statement
| rename_statement
| drop_statement
| case_statement
| if_statement
| truncate_statement
| analyze_statement
| show_statement
| start_transaction_statement
| commit_statement
| rollback_statement
| explain_statement
| describe_statement
| declare_statement
| signal_statement
| resignal_statement
| call_statement
| savepoint_statement
| rollback_savepoint_statement
| release_savepoint_statement
| grant_statement
| revoke_statement
| begin_end_block
| flush_statement

create_table_prefix:
  CREATE temp_opt TABLE not_exists_opt table_name
  {
    var ne bool
    if $4 != 0 {
      ne = true
    }

    var neTemp bool
    if $2 != 0 {
      neTemp = true
    }

    $$ = &DDL{Action: CreateStr, Table: $5, IfNotExists: ne, Temporary: neTemp}
  }

table_spec:
  '(' table_column_list ')' table_option_list
  {
    $$ = $2
    $$.Options = $4
  }

table_column_list:
  column_definition_for_create
  {
    $$ = &TableSpec{}
    $$.AddColumn($1)
  }
| check_constraint_definition
  {
    $$ = &TableSpec{}
    $$.AddConstraint($1)
  }
| column_definition_for_create check_constraint_definition
  {
    $$ = &TableSpec{}
    $$.AddColumn($1)
    $$.AddConstraint($2)
  }
| table_column_list ',' column_definition_for_create
  {
    $$.AddColumn($3)
  }
| table_column_list ',' column_definition_for_create check_constraint_definition
  {
    $$.AddColumn($3)
    $$.AddConstraint($4)
  }
| table_column_list ',' index_definition
  {
    $$.AddIndex($3)
  }
| table_column_list ',' constraint_definition
  {
    $$.AddConstraint($3)
  }
| table_column_list ',' check_constraint_definition
  {
    $$.AddConstraint($3)
  }

column_definition:
  ID column_type column_type_options
  {
    if err := $2.merge($3); err != nil {
      yylex.Error(err.Error())
      return 1
    }
    $$ = &ColumnDefinition{Name: NewColIdent(string($1)), Type: $2}
  }
| column_name_safe_reserved_keyword column_type column_type_options
  {
    if err := $2.merge($3); err != nil {
      yylex.Error(err.Error())
      return 1
    }
    $$ = &ColumnDefinition{Name: NewColIdent(string($1)), Type: $2}
  }

column_definition_for_create:
  reserved_sql_id column_type column_type_options
  {
    if err := $2.merge($3); err != nil {
      yylex.Error(err.Error())
      return 1
    }
    $$ = &ColumnDefinition{Name: $1, Type: $2}
  }

stored_opt:
  {
    $$ = BoolVal(false)
  }
| VIRTUAL
  {
    $$ = BoolVal(false)
  }
| STORED
  {
    $$ = BoolVal(true)
  }

column_type_options:
  {
    $$ = ColumnType{}
  }
| column_type_options NULL
  {
    opt := ColumnType{Null: BoolVal(true), NotNull: BoolVal(false), sawnull: true}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options NOT NULL
  {
    opt := ColumnType{Null: BoolVal(false), NotNull: BoolVal(true), sawnull: true}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options column_default
  {
    opt := ColumnType{Default: $2}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options on_update
  {
    opt := ColumnType{OnUpdate: $2}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options auto_increment
  {
    opt := ColumnType{Autoincrement: $2, sawai: true}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options column_key
  {
    opt := ColumnType{KeyOpt: $2}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options column_comment
  {
    opt := ColumnType{Comment: $2}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options AS openb value_expression closeb stored_opt
  {
    opt := ColumnType{GeneratedExpr: $4, Stored: $6}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }
| column_type_options GENERATED ALWAYS AS openb value_expression closeb stored_opt
  {
    opt := ColumnType{GeneratedExpr: $6, Stored: $8}
    if err := $1.merge(opt); err != nil {
    	yylex.Error(err.Error())
    	return 1
    }
    $$ = $1
  }

column_type:
  numeric_type unsigned_opt zero_fill_opt
  {
    $$ = $1
    $$.Unsigned = $2
    $$.Zerofill = $3
  }
| char_type
| time_type
| spatial_type

numeric_type:
  int_type length_opt
  {
    $$ = $1
    $$.Length = $2
  }
| decimal_type
  {
    $$ = $1
  }

int_type:
  BIT
  {
    $$ = ColumnType{Type: string($1)}
  }
| BOOL
  {
    $$ = ColumnType{Type: string($1)}
  }
| BOOLEAN
  {
    $$ = ColumnType{Type: string($1)}
  }
| TINYINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| SMALLINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| MEDIUMINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| INT
  {
    $$ = ColumnType{Type: string($1)}
  }
| INTEGER
  {
    $$ = ColumnType{Type: string($1)}
  }
| BIGINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| SERIAL
  {
    $$ = ColumnType{Type: "bigint", Unsigned: true, NotNull: true, Autoincrement: true, KeyOpt: colKeyUnique}
  }

decimal_type:
REAL float_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DOUBLE float_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DOUBLE PRECISION float_length_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2)}
    $$.Length = $3.Length
    $$.Scale = $3.Scale
  }
| FLOAT_TYPE decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DECIMAL decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| NUMERIC decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DEC decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| FIXED decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }

time_type:
  DATE
  {
    $$ = ColumnType{Type: string($1)}
  }
| TIME length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| TIMESTAMP length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| DATETIME length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| YEAR
  {
    $$ = ColumnType{Type: string($1)}
  }

char_type:
  CHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| CHARACTER length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| NATIONAL CHAR length_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2), Length: $3}
  }
| NATIONAL CHARACTER length_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2), Length: $3}
  }
| NCHAR length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| VARCHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| CHARACTER VARYING length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2), Length: $3, Charset: $4, Collate: $5}
  }
| NVARCHAR length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| NATIONAL VARCHAR length_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2), Length: $3}
  }
| NATIONAL CHARACTER VARYING length_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2) + " " + string($3), Length: $4}
  }
| BINARY length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| VARBINARY length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| TEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| TINYTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| MEDIUMTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| LONGTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| LONG charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| LONG VARCHAR charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1) + " " + string($2), Charset: $3, Collate: $4}
  }
| BLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| TINYBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| MEDIUMBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| LONGBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| JSON
  {
    $$ = ColumnType{Type: string($1)}
  }
| ENUM '(' enum_values ')' charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), EnumValues: $3, Charset: $5, Collate: $6}
  }
// need set_values / SetValues ?
| SET '(' enum_values ')' charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), EnumValues: $3, Charset: $5, Collate: $6}
  }

spatial_type:
  GEOMETRY
  {
    $$ = ColumnType{Type: string($1)}
  }
| POINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| LINESTRING
  {
    $$ = ColumnType{Type: string($1)}
  }
| POLYGON
  {
    $$ = ColumnType{Type: string($1)}
  }
| GEOMETRYCOLLECTION
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTIPOINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTILINESTRING
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTIPOLYGON
  {
    $$ = ColumnType{Type: string($1)}
  }

enum_values:
  STRING
  {
    $$ = make([]string, 0, 4)
    $$ = append($$, string($1))
  }
| enum_values ',' STRING
  {
    $$ = append($1, string($3))
  }

length_opt:
  {
    $$ = nil
  }
| '(' INTEGRAL ')'
  {
    $$ = NewIntVal($2)
  }

float_length_opt:
  {
    $$ = LengthScaleOption{}
  }
| '(' INTEGRAL ',' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
        Scale: NewIntVal($4),
    }
  }

decimal_length_opt:
  {
    $$ = LengthScaleOption{}
  }
| '(' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
    }
  }
| '(' INTEGRAL ',' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
        Scale: NewIntVal($4),
    }
  }

unsigned_opt:
  {
    $$ = BoolVal(false)
  }
| UNSIGNED
  {
    $$ = BoolVal(true)
  }

zero_fill_opt:
  {
    $$ = BoolVal(false)
  }
| ZEROFILL
  {
    $$ = BoolVal(true)
  }

column_default:
  DEFAULT value_expression
  {
    $$ = $2
  }

on_update:
  ON UPDATE function_call_nonkeyword
  {
    $$ = $3
  }

auto_increment:
  AUTO_INCREMENT
  {
    $$ = BoolVal(true)
  }

charset_opt:
  {
    $$ = ""
  }
| CHARACTER SET ID
  {
    $$ = string($3)
  }
| CHARACTER SET BINARY
  {
    $$ = string($3)
  }

collate_opt:
  {
    $$ = ""
  }
| COLLATE ID
  {
    $$ = string($2)
  }
| COLLATE STRING
  {
    $$ = string($2)
  }

default_keyword_opt:
  {
    $$ = false
  }
| DEFAULT
  {
    $$ = true
  }

creation_option_opt:
  {
    $$ = nil
  }
| creation_option
  {
    $$ = $1
  }

creation_option:
  charset_default_opt
  {
    $$ = []*CharsetAndCollate{$1}
  }
| collate_default_opt
  {
    $$ = []*CharsetAndCollate{$1}
  }
| encryption_default_opt
  {
    $$ = []*CharsetAndCollate{$1}
  }
| creation_option collate_default_opt
  {
    $$ = append($1,$2)
  }
| creation_option charset_default_opt
  {
    $$ = append($1,$2)
  }
| creation_option encryption_default_opt
  {
    $$ = append($1,$2)
  }

charset_default_opt:
  default_keyword_opt CHARACTER SET equal_opt ID
  {
    $$ = &CharsetAndCollate{Type: string($2) + " " + string($3), Value: string($5), IsDefault: $1}
  }
| default_keyword_opt CHARACTER SET equal_opt BINARY
  {
    $$ = &CharsetAndCollate{Type: string($2) + " " + string($3), Value: string($5), IsDefault: $1}
  }
| default_keyword_opt CHARSET equal_opt ID
  {
    $$ = &CharsetAndCollate{Type: string($2), Value: string($4), IsDefault: $1}
  }
| default_keyword_opt CHARSET equal_opt BINARY
  {
    $$ = &CharsetAndCollate{Type: string($2), Value: string($4), IsDefault: $1}
  }

collate_default_opt:
  default_keyword_opt COLLATE equal_opt ID
  {
    $$ = &CharsetAndCollate{Type: string($2), Value: string($4), IsDefault: $1}
  }
| default_keyword_opt COLLATE equal_opt BINARY
  {
    $$ = &CharsetAndCollate{Type: string($2), Value: string($4), IsDefault: $1}
  }

encryption_default_opt:
  default_keyword_opt ENCRYPTION equal_opt STRING
  {
    $$ = &CharsetAndCollate{Type: string($2), Value: string($4), IsDefault: $1}
  }

column_key:
  PRIMARY KEY
  {
    $$ = colKeyPrimary
  }
| KEY
  {
    $$ = colKey
  }
| UNIQUE KEY
  {
    $$ = colKeyUniqueKey
  }
| UNIQUE
  {
    $$ = colKeyUnique
  }
| FULLTEXT KEY
  {
    $$ = colKeyFulltextKey
  }

column_comment:
  COMMENT_KEYWORD STRING
  {
    $$ = NewStrVal($2)
  }

flush_statement:
  FLUSH flush_type_opt flush_option
  {
    $$ = &Flush{Type: $2, Option: $3}
  }

flush_option:
  BINARY LOGS
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2)}
  }
| ENGINE LOGS
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2)}
  }
| ERROR LOGS
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2)}
  }
| GENERAL LOGS
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2)}
  }
| HOSTS
  {
    $$ = &FlushOption{Name: string($1)}
  }
| LOGS
  {
    $$ = &FlushOption{Name: string($1)}
  }
| PRIVILEGES
  {
    $$ = &FlushOption{Name: string($1)}
  }
| OPTIMIZER_COSTS
  {
    $$ = &FlushOption{Name: string($1)}
  }
| RELAY LOGS relay_logs_attribute
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2), Channel: $3}
  }
| SLOW LOGS
  {
    $$ = &FlushOption{Name: string($1) + " " +  string($2)}
  }
| STATUS
  {
    $$ = &FlushOption{Name: string($1)}
  }
| USER_RESOURCES
  {
    $$ = &FlushOption{Name: string($1)}
  }

relay_logs_attribute:
  { $$ = "" }
| FOR CHANNEL STRING
  { $$ = string($3) }

flush_type:
  NO_WRITE_TO_BINLOG
  { $$ = string($1) }
| LOCAL
  { $$ = string($1) }

flush_type_opt:
  { $$ = "" }
| flush_type
  { $$ = $1 }

index_definition:
  index_info '(' index_column_list ')' index_option_list
  {
    $$ = &IndexDefinition{Info: $1, Columns: $3, Options: $5}
  }
| index_info '(' index_column_list ')'
  {
    $$ = &IndexDefinition{Info: $1, Columns: $3}
  }

index_option_list_opt:
  {
    $$ = nil
  }
| index_option_list
  {
    $$ = $1
  }

index_option_list:
  index_option
  {
    $$ = []*IndexOption{$1}
  }
| index_option_list index_option
  {
    $$ = append($$, $2)
  }

index_option:
  USING ID
  {
    $$ = &IndexOption{Name: string($1), Using: string($2)}
  }
| KEY_BLOCK_SIZE equal_opt INTEGRAL
  {
    // should not be string
    $$ = &IndexOption{Name: string($1), Value: NewIntVal($3)}
  }
| COMMENT_KEYWORD STRING
  {
    $$ = &IndexOption{Name: string($1), Value: NewStrVal($2)}
  }

equal_opt:
  /* empty */
  {
    $$ = ""
  }
| '='
  {
    $$ = string($1)
  }

index_info:
  PRIMARY KEY
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent("PRIMARY"), Primary: true, Unique: true}
  }
| CONSTRAINT ID PRIMARY KEY
  {
    $$ = &IndexInfo{Type: string($3) + " " + string($4), Name: NewColIdent(string($2)), Primary: true, Unique: true}
  }
| SPATIAL index_or_key name_opt
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent($3), Spatial: true, Unique: false}
  }
| FULLTEXT index_or_key_opt name_opt
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent($3), Fulltext: true}
  }
| CONSTRAINT name_opt UNIQUE index_or_key_opt name_opt
  {
    var name string
    name = $2
    if name == "" {
      name = $5
    }
    $$ = &IndexInfo{Type: string($3) + " " + string($4), Name: NewColIdent(name), Unique: true}
  }
| UNIQUE index_or_key name_opt
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent($3), Unique: true}
  }
| UNIQUE name_opt
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent($2), Unique: true}
  }
| index_or_key name_opt
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent($2), Unique: false}
  }

indexes_or_keys:
  INDEX
  {
    $$ = string($1)
  }
| INDEXES
  {
    $$ = string($1)
  }
| KEYS
  {
    $$ = string($1)
  }

index_or_key:
  INDEX
  {
    $$ = string($1)
  }
| KEY
  {
    $$ = string($1)
  }

index_or_key_opt:
  {
    $$ = ""
  }
| index_or_key
  {
    $$ = $1
  }

name_opt:
  {
    $$ = ""
  }
| ID
  {
    $$ = string($1)
  }

index_column_list:
  index_column
  {
    $$ = []*IndexColumn{$1}
  }
| index_column_list ',' index_column
  {
    $$ = append($$, $3)
  }

index_column:
  sql_id length_opt asc_desc_opt
  {
      $$ = &IndexColumn{Column: $1, Length: $2, Order: $3}
  }
| column_name_safe_reserved_keyword length_opt asc_desc_opt
  {
      $$ = &IndexColumn{Column: NewColIdent(string($1)), Length: $2, Order: $3}
  }

constraint_definition:
  CONSTRAINT ID constraint_info
  {
    $$ = &ConstraintDefinition{Name: string($2), Details: $3}
  }
|  CONSTRAINT column_name_safe_reserved_keyword constraint_info
   {
     $$ = &ConstraintDefinition{Name: string($2), Details: $3}
   }
|  constraint_info
  {
    $$ = &ConstraintDefinition{Details: $1}
  }

constraint_info:
  FOREIGN KEY '(' column_list ')' REFERENCES table_name '(' column_list ')'
  {
    $$ = &ForeignKeyDefinition{Source: $4, ReferencedTable: $7, ReferencedColumns: $9}
  }
| FOREIGN KEY '(' column_list ')' REFERENCES table_name '(' column_list ')' fk_on_delete
  {
    $$ = &ForeignKeyDefinition{Source: $4, ReferencedTable: $7, ReferencedColumns: $9, OnDelete: $11}
  }
| FOREIGN KEY '(' column_list ')' REFERENCES table_name '(' column_list ')' fk_on_update
  {
    $$ = &ForeignKeyDefinition{Source: $4, ReferencedTable: $7, ReferencedColumns: $9, OnUpdate: $11}
  }
| FOREIGN KEY '(' column_list ')' REFERENCES table_name '(' column_list ')' fk_on_delete fk_on_update
  {
    $$ = &ForeignKeyDefinition{Source: $4, ReferencedTable: $7, ReferencedColumns: $9, OnDelete: $11, OnUpdate: $12}
  }
| FOREIGN KEY '(' column_list ')' REFERENCES table_name '(' column_list ')' fk_on_update fk_on_delete
  {
    $$ = &ForeignKeyDefinition{Source: $4, ReferencedTable: $7, ReferencedColumns: $9, OnDelete: $12, OnUpdate: $11}
  }

check_constraint_definition:
  CONSTRAINT ID check_constraint_info
  {
    $$ = &ConstraintDefinition{Name: string($2), Details: $3}
  }
| CONSTRAINT column_name_safe_reserved_keyword check_constraint_info
    {
      $$ = &ConstraintDefinition{Name: string($2), Details: $3}
    }
| CONSTRAINT check_constraint_info
  {
    $$ = &ConstraintDefinition{Details: $2}
  }
|  check_constraint_info
  {
    $$ = &ConstraintDefinition{Details: $1}
  }

check_constraint_info:
  CHECK '(' expression ')' enforced_opt
  {
    $$ = &CheckConstraintDefinition{Expr: $3, Enforced: $5}
  }

from_or_in:
  FROM
  {
    $$ = string($1)
  }
| IN
  {
    $$ = string($1)
  }

show_database_opt:
  {
    $$ = ""
  }
| FROM ID
  {
    $$ = string($2)
  }
| IN ID
  {
    $$ = string($2)
  }

fk_on_delete:
  ON DELETE fk_reference_action
  {
    $$ = $3
  }

fk_on_update:
  ON UPDATE fk_reference_action
  {
    $$ = $3
  }

fk_reference_action:
  RESTRICT
  {
    $$ = Restrict
  }
| CASCADE
  {
    $$ = Cascade
  }
| NO ACTION
  {
    $$ = NoAction
  }
| SET DEFAULT
  {
    $$ = SetDefault
  }
| SET NULL
  {
    $$ = SetNull
  }

enforced_opt:
  {
    $$ = true
  }
| ENFORCED
  {
    $$ = true
  }
| NOT ENFORCED
  {
    $$ = false
  }

table_option_list:
  {
    $$ = ""
  }
| table_option
  {
    $$ = " " + string($1)
  }
| table_option_list ',' table_option
  {
    $$ = string($1) + ", " + string($3)
  }

// rather than explicitly parsing the various keywords for table options,
// just accept any number of keywords, IDs, strings, numbers, and '='
table_option:
  table_opt_value
  {
    $$ = $1
  }
| table_option table_opt_value
  {
    $$ = $1 + " " + $2
  }
| table_option '=' table_opt_value
  {
    $$ = $1 + "=" + $3
  }

table_opt_value:
  reserved_sql_id
  {
    $$ = $1.String()
  }
| STRING
  {
    $$ = "'" + string($1) + "'"
  }
| INTEGRAL
  {
    $$ = string($1)
  }

constraint_symbol_opt:
  {
    $$ = ""
  }
| CONSTRAINT ID
  {
    $$ = string($2)
  }

pk_name_opt:
  {
    $$ = string("")
  }
| CONSTRAINT ID
  {
    $$ = string($2)
  }

alter_statement:
  alter_table_statement

alter_table_statement:
  ALTER ignore_opt TABLE table_name alter_table_statement_list
  {
    for i := 0; i < len($5); i++ {
      if $5[i].Action == RenameStr {
        $5[i].FromTables = append(TableNames{$4}, $5[i].FromTables...)
      } else {
        $5[i].Table = $4
      }
    }
    $$ = &MultiAlterDDL{Table: $4, Statements: $5}
  }

alter_table_statement_list:
  alter_table_statement_part
  {
    $$ = []*DDL{$1}
  }
| alter_table_statement_list ',' alter_table_statement_part
  {
    $$ = append($$, $3)
  }

alter_table_statement_part:
  ADD column_opt '(' column_definition ')'
  {
    ddl := &DDL{Action: AlterStr, ColumnAction: AddStr, TableSpec: &TableSpec{}}
    ddl.TableSpec.AddColumn($4)
    ddl.Column = $4.Name
    $$ = ddl
  }
| ADD column_opt column_definition column_order_opt
  {
    ddl := &DDL{Action: AlterStr, ColumnAction: AddStr, TableSpec: &TableSpec{}, ColumnOrder: $4}
    ddl.TableSpec.AddColumn($3)
    ddl.Column = $3.Name
    $$ = ddl
  }
| DROP column_opt ID
  {
    $$ = &DDL{Action: AlterStr, ColumnAction: DropStr, Column: NewColIdent(string($3))}
  }
| RENAME COLUMN ID to_or_as ID
  {
    $$ = &DDL{Action: AlterStr, ColumnAction: RenameStr, Column: NewColIdent(string($3)), ToColumn: NewColIdent(string($5))}
  }
| RENAME to_opt table_name
  {
    // Change this to a rename statement
    $$ = &DDL{Action: RenameStr, ToTables: TableNames{$3}}
  }
| ADD index_or_key name_opt using_opt '(' index_column_list ')' index_option_list_opt
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: CreateStr, ToName: NewColIdent($3),  Using: $4, Columns: $6, Options: $8}}
  }
| ADD constraint_symbol_opt key_type index_or_key_opt name_opt using_opt '(' index_column_list ')' index_option_list_opt
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: CreateStr, ToName: NewColIdent($5), Type: $3, Using: $6, Columns: $8, Options: $10}}
  }
| DROP CONSTRAINT ID
  {
    $$ = &DDL{Action: AlterStr, ConstraintAction: DropStr, TableSpec: &TableSpec{Constraints:
        []*ConstraintDefinition{&ConstraintDefinition{Name: string($3)}}}}
  }
| DROP CONSTRAINT column_name_safe_reserved_keyword
  {
    $$ = &DDL{Action: AlterStr, ConstraintAction: DropStr, TableSpec: &TableSpec{Constraints:
        []*ConstraintDefinition{&ConstraintDefinition{Name: string($3)}}}}
  }
| DROP CHECK ID
  {
    $$ = &DDL{Action: AlterStr, ConstraintAction: DropStr, TableSpec: &TableSpec{Constraints:
        []*ConstraintDefinition{&ConstraintDefinition{Name: string($3), Details: &CheckConstraintDefinition{}}}}}
  }
| DROP CHECK column_name_safe_reserved_keyword
  {
    $$ = &DDL{Action: AlterStr, ConstraintAction: DropStr, TableSpec: &TableSpec{Constraints:
        []*ConstraintDefinition{&ConstraintDefinition{Name: string($3), Details: &CheckConstraintDefinition{}}}}}
  }
| DROP index_or_key sql_id
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: DropStr, ToName: $3}}
  }
| RENAME index_or_key sql_id TO sql_id
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: RenameStr, FromName: $3, ToName: $5}}
  }
| MODIFY column_opt column_definition column_order_opt
  {
    ddl := &DDL{Action: AlterStr, ColumnAction: ModifyStr, TableSpec: &TableSpec{}, ColumnOrder: $4}
    ddl.TableSpec.AddColumn($3)
    ddl.Column = $3.Name
    $$ = ddl
  }
| CHANGE column_opt ID column_definition column_order_opt
  {
    ddl := &DDL{Action: AlterStr, ColumnAction: ChangeStr, TableSpec: &TableSpec{}, Column: NewColIdent(string($3)), ColumnOrder: $5}
    ddl.TableSpec.AddColumn($4)
    $$ = ddl
  }
| partition_operation
  {
    $$ = &DDL{Action: AlterStr, PartitionSpec: $1}
  }
| ADD constraint_definition
  {
    ddl := &DDL{Action: AlterStr, ConstraintAction: AddStr, TableSpec: &TableSpec{}}
    ddl.TableSpec.AddConstraint($2)
    $$ = ddl
  }
| ADD check_constraint_definition
  {
    ddl := &DDL{Action: AlterStr, ConstraintAction: AddStr, TableSpec: &TableSpec{}}
    ddl.TableSpec.AddConstraint($2)
    $$ = ddl
  }
| DROP FOREIGN KEY ID
  {
    $$ = &DDL{Action: AlterStr, ConstraintAction: DropStr, TableSpec: &TableSpec{Constraints:
        []*ConstraintDefinition{&ConstraintDefinition{Name: string($4), Details: &ForeignKeyDefinition{}}}}}
  }
| AUTO_INCREMENT equal_opt expression
  {
    $$ = &DDL{Action: AlterStr, AutoIncSpec: &AutoIncSpec{Value: $3}}
  }
| ALTER column_opt sql_id SET DEFAULT value_expression
  {
    $$ = &DDL{Action: AlterStr, DefaultSpec: &DefaultSpec{Action: SetStr, Column: $3, Value: $6}}
  }
| ALTER column_opt sql_id DROP DEFAULT
  {
    $$ = &DDL{Action: AlterStr, DefaultSpec: &DefaultSpec{Action: DropStr, Column: $3}}
  }
| DROP PRIMARY KEY
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: DropStr, Type: PrimaryStr}}
  }
| ADD pk_name_opt PRIMARY KEY '(' index_column_list ')' index_option_list_opt
  {
    ddl := &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: CreateStr}}
    ddl.IndexSpec = &IndexSpec{Action: CreateStr, Using: NewColIdent(""), ToName: NewColIdent($2), Type: PrimaryStr, Columns: $6, Options: $8}
    $$ = ddl
  }
| DISABLE KEYS
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: string($1)}}
  }
| ENABLE KEYS
  {
    $$ = &DDL{Action: AlterStr, IndexSpec: &IndexSpec{Action: string($1)}}
  }

column_order_opt:
  {
    $$ = nil
  }
| FIRST
  {
    $$ = &ColumnOrder{First: true}
  }
| AFTER ID
  {
    $$ = &ColumnOrder{AfterColumn: NewColIdent(string($2))}
  }

column_opt:
  { }
| COLUMN
  { }

partition_operation:
  REORGANIZE PARTITION sql_id INTO openb partition_definitions closeb
  {
    $$ = &PartitionSpec{Action: ReorganizeStr, Name: $3, Definitions: $6}
  }

partition_definitions:
  partition_definition
  {
    $$ = []*PartitionDefinition{$1}
  }
| partition_definitions ',' partition_definition
  {
    $$ = append($1, $3)
  }

partition_definition:
  PARTITION sql_id VALUES LESS THAN openb value_expression closeb
  {
    $$ = &PartitionDefinition{Name: $2, Limit: $7}
  }
| PARTITION sql_id VALUES LESS THAN openb MAXVALUE closeb
  {
    $$ = &PartitionDefinition{Name: $2, Maxvalue: true}
  }

rename_statement:
  RENAME TABLE rename_list
  {
    $$ = $3
  }
| RENAME USER rename_user_list
  {
    $$ = &RenameUser{Accounts: $3}
  }

rename_list:
  table_name TO table_name
  {
    $$ = &DDL{Action: RenameStr, FromTables: TableNames{$1}, ToTables: TableNames{$3}}
  }
| rename_list ',' table_name TO table_name
  {
    $$ = $1
    $$.FromTables = append($$.FromTables, $3)
    $$.ToTables = append($$.ToTables, $5)
  }

rename_user_list:
  account_name TO account_name
  {
    $$ = []AccountRename{{From: $1, To: $3}}
  }
| rename_user_list ',' account_name TO account_name
  {
    $$ = append($1, AccountRename{From: $3, To: $5})
  }

drop_statement:
  DROP TABLE exists_opt table_name_list drop_statement_action
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DDL{Action: DropStr, FromTables: $4, IfExists: exists}
  }
| DROP INDEX sql_id ON table_name
  {
    $$ = &DDL{Action: AlterStr, Table: $5, IndexSpec: &IndexSpec{Action: DropStr, ToName: $3}}
  }
| DROP VIEW exists_opt view_name_list
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DDL{Action: DropStr, FromViews: $4, IfExists: exists}
  }
| DROP DATABASE exists_opt ID
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DBDDL{Action: DropStr, DBName: string($4), IfExists: exists}
  }
| DROP SCHEMA exists_opt ID
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DBDDL{Action: DropStr, DBName: string($4), IfExists: exists}
  }
| DROP TRIGGER exists_opt trigger_name
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DDL{Action: DropStr, TriggerSpec: &TriggerSpec{TrigName: $4}, IfExists: exists}
  }
| DROP PROCEDURE exists_opt procedure_name
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DDL{Action: DropStr, ProcedureSpec: &ProcedureSpec{ProcName: $4}, IfExists: exists}
  }
| DROP USER exists_opt account_name_list
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DropUser{IfExists: exists, AccountNames: $4}
  }
| DROP ROLE exists_opt role_name_list
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DropRole{IfExists: exists, Roles: $4}
  }

drop_statement_action:
  {

  }
| RESTRICT
  {
    $$ = Restrict
  }
| CASCADE
  {
    $$ = Cascade
  }

truncate_statement:
  TRUNCATE TABLE table_name
  {
    $$ = &DDL{Action: TruncateStr, Table: $3}
  }
| TRUNCATE table_name
  {
    $$ = &DDL{Action: TruncateStr, Table: $2}
  }
analyze_statement:
  ANALYZE TABLE table_name
  {
    $$ = &DDL{Action: AlterStr, Table: $3}
  }

show_statement:
  SHOW BINARY ID /* SHOW BINARY LOGS */
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
/* SHOW CHARACTER SET and SHOW CHARSET are equivalent */
| SHOW CHARACTER SET like_or_where_opt
  {
    $$ = &Show{Type: CharsetStr, Filter: $4}
  }
| SHOW CHARSET like_or_where_opt
  {
    $$ = &Show{Type: string($2), Filter: $3}
  }
| SHOW CREATE DATABASE not_exists_opt ID
  {
    $$ = &Show{Type: string($2) + " " + string($3), IfNotExists: $4 == 1, Database: string($5)}
  }
| SHOW CREATE SCHEMA not_exists_opt ID
  {
    $$ = &Show{Type: string($2) + " " + string($3), IfNotExists: $4 == 1, Database: string($5)}
  }
| SHOW CREATE TABLE table_name as_of_opt
  {
    showTablesOpt := &ShowTablesOpt{AsOf:$5}
    $$ = &Show{Type: string($2) + " " + string($3), Table: $4, ShowTablesOpt: showTablesOpt}
  }
| SHOW CREATE PROCEDURE table_name
  {
    $$ = &Show{Type: CreateProcedureStr, Table: $4}
  }
| SHOW CREATE TRIGGER table_name
  {
    $$ = &Show{Type: CreateTriggerStr, Table: $4}
  }
| SHOW CREATE VIEW table_name
  {
    $$ = &Show{Type: string($2) + " " + string($3), Table: $4}
  }
| SHOW DATABASES
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW SCHEMAS
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW ENGINES
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW indexes_or_keys from_or_in table_name show_database_opt where_expression_opt
  {
    $$ = &Show{Type: IndexStr, Table: $4, Database: $5, ShowIndexFilterOpt: $6}
  }
| SHOW PLUGINS
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW PROCEDURE STATUS like_or_where_opt
  {
    $$ = &Show{Type: string($2) + " " + string($3), Filter: $4}
  }
| SHOW FUNCTION STATUS like_or_where_opt
  {
    $$ = &Show{Type: string($2) + " " + string($3), Filter: $4}
  }
| SHOW show_session_or_global STATUS like_or_where_opt
  {
    $$ = &Show{Scope: $2, Type: string($3), Filter: $4}
  }
| SHOW TABLE STATUS from_database_opt like_or_where_opt
  {
    $$ = &Show{Type: string($2) + " " + string($3), Database: $4, Filter:$5}
  }
| SHOW full_opt columns_or_fields FROM table_name from_database_opt as_of_opt like_or_where_opt
  {
    showTablesOpt := &ShowTablesOpt{DbName:$6, AsOf:$7, Filter:$8}
    $$ = &Show{Type: string($3), ShowTablesOpt: showTablesOpt, Table: $5, Full: $2}
  }
| SHOW full_opt TABLES from_database_opt as_of_opt like_or_where_opt
  {
    showTablesOpt := &ShowTablesOpt{DbName:$4, Filter:$6, AsOf:$5}
    $$ = &Show{Type: string($3), ShowTablesOpt: showTablesOpt, Full: $2}
  }
| SHOW full_opt PROCESSLIST
  {
    $$ = &Show{Type: string($3), Full: $2}
  }
| SHOW full_opt TRIGGERS from_database_opt like_or_where_opt
  {
    $$ = &Show{Type: string($3), ShowTablesOpt: &ShowTablesOpt{DbName: $4, Filter: $5}, Full: $2}
  }
| SHOW show_session_or_global VARIABLES like_or_where_opt
  {
    $$ = &Show{Scope: $2, Type: string($3), Filter: $4}
  }
| SHOW COLLATION
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW COLLATION WHERE expression
  {
    // Cannot dereference $4 directly, or else the parser stackcannot be pooled. See yyParsePooled
    showCollationFilterOpt := $4
    $$ = &Show{Type: string($2), ShowCollationFilterOpt: &showCollationFilterOpt}
  }
| SHOW COLLATION naked_like
  {
    // Cannot dereference $3 directly, or else the parser stackcannot be pooled. See yyParsePooled
    cmp := $3.(*ComparisonExpr)
    cmp.Left = &ColName{Name: NewColIdent("collation")}
    var ex Expr = cmp
    $$ = &Show{Type: string($2), ShowCollationFilterOpt: &ex}
  }
| SHOW GRANTS
  {
    $$ = &ShowGrants{}
  }
| SHOW GRANTS FOR account_name
  {
    an := $4
    $$ = &ShowGrants{For: &an}
  }
| SHOW GRANTS FOR CURRENT_USER func_parens_opt
  {
    $$ = &ShowGrants{CurrentUser: true}
  }
| SHOW GRANTS FOR account_name USING role_name_list
  {
    an := $4
    $$ = &ShowGrants{For: &an, Using: $6}
  }
| SHOW PRIVILEGES
  {
    $$ = &ShowPrivileges{}
  }
| SHOW COUNT openb '*' closeb WARNINGS
  {
    $$ = &Show{Type: string($6), CountStar: true}
  }
| SHOW COUNT openb '*' closeb ERRORS
  {
    $$ = &Show{Type: string($6), CountStar: true}
  }
| SHOW WARNINGS limit_opt
  {
    $$ = &Show{Type: string($2), Limit: $3}
  }
| SHOW ERRORS limit_opt
  {
    $$ = &Show{Type: string($2), Limit: $3}
  }

naked_like:
LIKE value_expression like_escape_opt
  {
    $$ = &ComparisonExpr{Operator: LikeStr, Right: $2, Escape: $3}
  }

full_opt:
  /* empty */
  {
    $$ = false
  }
| FULL
  {
    $$ = true
  }

columns_or_fields:
  COLUMNS
  {
      $$ = string($1)
  }
| FIELDS
  {
      $$ = string($1)
  }

from_database_opt:
  /* empty */
  {
    $$ = ""
  }
| FROM table_id
  {
    $$ = $2.v
  }
| IN table_id
  {
    $$ = $2.v
  }

like_or_where_opt:
  /* empty */
  {
    $$ = nil
  }
| LIKE STRING
  {
    $$ = &ShowFilter{Like:string($2)}
  }
| WHERE expression
  {
    $$ = &ShowFilter{Filter:$2}
  }

show_session_or_global:
  /* empty */
  {
    $$ = ""
  }
| SESSION
  {
    $$ = SessionStr
  }
| GLOBAL
  {
    $$ = GlobalStr
  }

use_statement:
  USE table_id
  {
    $$ = &Use{DBName: $2}
  }
| USE
  {
    $$ = &Use{DBName:TableIdent{v:""}}
  }

begin_statement:
  BEGIN
  {
    $$ = &Begin{}
  }
| start_transaction_statement
  {
    $$ = $1
  }

start_transaction_statement:
  START TRANSACTION
  {
    $$ = &Begin{}
  }
| START TRANSACTION READ WRITE
  {
    $$ = &Begin{TransactionCharacteristic: TxReadWrite}
  }
 | START TRANSACTION READ ONLY
  {
    $$ = &Begin{TransactionCharacteristic: TxReadOnly}
  }

commit_statement:
  COMMIT
  {
    $$ = &Commit{}
  }

rollback_statement:
  ROLLBACK
  {
    $$ = &Rollback{}
  }

savepoint_statement:
  SAVEPOINT ID
  {
    $$ = &Savepoint{Identifier: string($2)}
  }

rollback_savepoint_statement:
  ROLLBACK TO ID
  {
    $$ = &RollbackSavepoint{Identifier: string($3)}
  }
| ROLLBACK WORK TO ID
  {
    $$ = &RollbackSavepoint{Identifier: string($4)}
  }
| ROLLBACK TO SAVEPOINT ID
  {
    $$ = &RollbackSavepoint{Identifier: string($4)}
  }
| ROLLBACK WORK TO SAVEPOINT ID
  {
    $$ = &RollbackSavepoint{Identifier: string($5)}
  }

release_savepoint_statement:
  RELEASE SAVEPOINT ID
  {
    $$ = &ReleaseSavepoint{Identifier: string($3)}
  }

describe:
  DESCRIBE { }
| DESC { }

explain_statement:
  explain_verb format_opt explainable_statement
  {
    $$ = &Explain{ExplainFormat: $2, Statement: $3}
  }
| explain_verb ANALYZE select_statement
  {
    $$ = &Explain{Analyze: true, ExplainFormat: TreeStr, Statement: $3}
  }

explainable_statement:
  select_statement
  {
    $$ = $1
  }
| delete_statement
| insert_statement
| update_statement

format_opt:
  {
    $$ = ""
  }
| FORMAT '=' ID
  {
    $$ = string($3)
  }

explain_verb:
  describe
| EXPLAIN

describe_statement:
  describe table_name as_of_opt
  // rewrite describe table as show columns from table
  {
    showTablesOpt := &ShowTablesOpt{AsOf:$3}
    $$ = &Show{Type: "columns", Table: $2, ShowTablesOpt: showTablesOpt}
  }

comment_opt:
  {
    setAllowComments(yylex, true)
  }
  comment_list
  {
    $$ = $2
    setAllowComments(yylex, false)
  }

comment_list:
  {
    $$ = nil
  }
| comment_list COMMENT
  {
    $$ = append($1, $2)
  }

union_op:
  UNION
  {
    $$ = UnionStr
  }
| UNION ALL
  {
    $$ = UnionAllStr
  }
| UNION DISTINCT
  {
    $$ = UnionDistinctStr
  }

sql_calc_found_rows_opt:
  {
    $$ = 0
  }
| SQL_CALC_FOUND_ROWS
  {
    $$ = 1
  }

cache_opt:
{
  $$ = ""
}
| SQL_NO_CACHE
{
  $$ = SQLNoCacheStr
}
| SQL_CACHE
{
  $$ = SQLCacheStr
}

distinct_opt:
  {
    $$ = ""
  }
| ALL
  {
    $$ = ""
  }
| DISTINCT
  {
    $$ = DistinctStr
  }

straight_join_opt:
  {
    $$ = ""
  }
| STRAIGHT_JOIN
  {
    $$ = StraightJoinHint
  }

select_expression_list:
  lexer_old_position select_expression lexer_old_position
  {
    if ae, ok := $2.(*AliasedExpr); ok {
      ae.StartParsePos = $1
      ae.EndParsePos = $3-1
    }
    $$ = SelectExprs{$2}
  }
| select_expression_list ',' lexer_old_position select_expression lexer_old_position
  {
    if ae, ok := $4.(*AliasedExpr); ok {
      ae.StartParsePos = $3
      ae.EndParsePos = $5-1
    }
    $$ = append($$, $4)
  }

// argument_expression is identical to select_expression except aliases are not allowed
argument_expression:
  '*'
  {
    $$ = &StarExpr{}
  }
| expression
  {
    $$ = &AliasedExpr{Expr: $1}
  }
| table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Name: $1}}
  }
| table_id '.' reserved_table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Qualifier: $1, Name: $3}}
  }

select_expression:
  '*'
  {
    $$ = &StarExpr{}
  }
| expression as_ci_opt
  {
    $$ = &AliasedExpr{Expr: $1, As: $2}
  }
| table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Name: $1}}
  }
| table_id '.' reserved_table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Qualifier: $1, Name: $3}}
  }

over:
  OVER sql_id
  {
    $$ = &Over{NameRef: $2}
  }
| OVER window_spec
  {
    $$ = (*Over)($2)
  }

window_spec:
  openb existing_window_name_opt partition_by_opt order_by_opt frame_opt closeb
  {
    $$ = &WindowDef{NameRef: $2, PartitionBy: $3, OrderBy: $4, Frame: $5}
  }

existing_window_name_opt:
  {
    $$ = ColIdent{}
  }
| ID {
    $$ = NewColIdent(string($1))
  }

partition_by_opt:
  {
    $$ = nil
  }
| PARTITION BY expression_list
  {
    $$ = $3
  }

over_opt:
  {
    $$ = nil
  }
| over
  {
    $$ = $1
  }

frame_opt:
  {
    $$ = nil
  }
| ROWS frame_extent
  {
    $$ = &Frame{Unit: RowsUnit, Extent: $2}
  }
| RANGE frame_extent
  {
    $$ = &Frame{Unit: RangeUnit, Extent: $2}
  }

// enforce PRECEDING < CURRENT ROW < FOLLOWING
frame_extent:
  BETWEEN frame_bound AND frame_bound
  {
    startBound := $2
    endBound := $4
    switch {
    case startBound.Type == UnboundedFollowing:
      yylex.Error("frame start cannot be UNBOUNDED FOLLOWING")
      return 1
    case endBound.Type == UnboundedPreceding:
      yylex.Error("frame end cannot be UNBOUNDED PRECEDING")
      return 1
    case startBound.Type == CurrentRow && endBound.Type == ExprPreceding:
      yylex.Error("frame starting from current row cannot have preceding rows")
      return 1
    case startBound.Type == ExprFollowing && endBound.Type == ExprPreceding:
      yylex.Error("frame starting from following row cannot have preceding rows")
      return 1
    case startBound.Type == ExprFollowing && endBound.Type == CurrentRow:
      yylex.Error("frame starting from following row cannot have preceding rows")
      return 1
    }
    $$ = &FrameExtent{Start: startBound, End: endBound}
  }
| frame_bound
  {
    startBound := $1
     switch {
     case startBound.Type == UnboundedFollowing:
       yylex.Error("frame start cannot be UNBOUNDED FOLLOWING")
       return 1
     case startBound.Type == ExprFollowing:
       yylex.Error("frame starting from following row cannot end with current row")
       return 1
     }
     $$ = &FrameExtent{Start: startBound}
  }

frame_bound:
UNBOUNDED PRECEDING
  {
    $$ = &FrameBound{Type: UnboundedPreceding}
  }
| UNBOUNDED FOLLOWING
  {
    $$ = &FrameBound{Type: UnboundedFollowing}
  }
| CURRENT ROW
  {
    $$ = &FrameBound{Type: CurrentRow}
  }
| integral_or_interval_expr PRECEDING
  {
    $$ = &FrameBound{
       Expr: $1,
       Type: ExprPreceding,
     }
  }
| integral_or_interval_expr FOLLOWING
  {
    $$ = &FrameBound{
       Expr: $1,
       Type: ExprFollowing,
     }
  }

window_opt:
  {
  $$ = nil
  }
| WINDOW window {
  $$ = $2
  }

window:
  window_definition
  {
    $$ = Window{$1}
  }
| window ',' window_definition {
    $$ = append($1, $3)
  }

window_definition:
  sql_id AS window_spec
  {
    def := $3
    def.Name = $1
    $$ = def
  }

// TODO : support prepared statements
integral_or_interval_expr:
INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| INTERVAL value sql_id
  {
    $$ = &IntervalExpr{Expr: $2, Unit: $3.String()}
  }

as_ci_opt:
  {
    $$ = ColIdent{}
  }
| col_alias
  {
    $$ = $1
  }
| AS col_alias
  {
    $$ = $2
  }

col_alias:
  ID
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }
| column_name_safe_reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }
| STRING
  {
    $$ = NewColIdent(string($1))
  }

table_references:
  table_reference
  {
    $$ = TableExprs{$1}
  }
| table_references ',' table_reference
  {
    $$ = append($$, $3)
  }

table_reference:
  table_factor
| join_table

table_factor:
  aliased_table_name
  {
    $$ = $1
  }
| subquery_or_values as_opt table_alias column_list_opt
  {
    switch n := $1.(type) {
    case *Subquery:
        n.Columns = $4
    case *ValuesStatement:
        n.Columns = $4
    }
    $$ = &AliasedTableExpr{Expr:$1, As: $3}
  }
| subquery_or_values
  {
    // missed alias for subquery
    yylex.Error("Every derived table must have its own alias")
    return 1
  }
| openb table_references closeb
  {
    $$ = &ParenTableExpr{Exprs: $2}
  }
| table_function

values_statement:
  VALUES row_list
  {
    $$ = &ValuesStatement{Rows: $2}
  }

row_list:
  ROW row_tuple
  {
    $$ = Values{$2}
  }
| row_list ',' ROW row_tuple
  {
    $$ = append($$, $4)
  }

aliased_table_name:
  table_name aliased_table_options
  {
    $$ = $2
    $$.Expr = $1
  }
| table_name PARTITION openb partition_list closeb aliased_table_options
  {
    $$ = $6
    $$.Expr = $1
    $$.Partitions = $4
  }

// All possible combinations of qualifiers for a table alias expression, declared in a single rule to avoid
// shift/reduce conflicts. To avoid grammar ambiguity, we can't always use optional rules that match empty
// (such as as_opt).
aliased_table_options:
  index_hint_list
  {
    $$ = &AliasedTableExpr{Hints: $1}
  }
| AS OF value_expression index_hint_list
  {
    $$ = &AliasedTableExpr{AsOf: &AsOf{Time: $3}, Hints: $4}
  }
| AS OF value_expression as_opt table_alias index_hint_list
  {
    $$ = &AliasedTableExpr{AsOf: &AsOf{Time: $3}, As: $5, Hints: $6}
  }
| AS table_alias index_hint_list
  {
    $$ = &AliasedTableExpr{As: $2, Hints: $3}
  }
| table_alias index_hint_list
  {
    $$ = &AliasedTableExpr{As: $1, Hints: $2}
  }
// SQL:2011 grammar would be nice to have, but it generates
// a parser conflict with FOR UPDATE which is hard to fix
//| FOR SYSTEM_TIME AS OF STRING
//  {
//    $$ = &AsOf{Time: string($5)}
//  }

as_of_opt:
  {
    $$ = nil
  }
| AS OF value_expression
  {
    $$ = $3
  }

column_list_opt:
  {
    $$ = nil
  }
| '(' column_list ')'
  {
    $$ = $2
  }

column_list:
  sql_id
  {
    $$ = Columns{$1}
  }
| column_list ',' sql_id
  {
    $$ = append($$, $3)
  }

partition_list:
  sql_id
  {
    $$ = Partitions{$1}
  }
| partition_list ',' sql_id
  {
    $$ = append($$, $3)
  }

table_function:
  ID openb argument_expression_list_opt closeb
  {
    $$ = &TableFuncExpr{Name: string($1), Exprs: $3}
  }

// There is a grammar conflict here:
// 1: INSERT INTO a SELECT * FROM b JOIN c ON b.i = c.i
// 2: INSERT INTO a SELECT * FROM b JOIN c ON DUPLICATE KEY UPDATE a.i = 1
// When yacc encounters the ON clause, it cannot determine which way to
// resolve. The %prec override below makes the parser choose the
// first construct, which automatically makes the second construct a
// syntax error. This is the same behavior as MySQL.
join_table:
  table_reference inner_join table_factor join_condition_opt
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference straight_join table_factor on_expression_opt
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference outer_join table_reference join_condition
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference natural_join table_factor
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3}
  }

join_condition:
  ON expression
  { $$ = JoinCondition{On: $2} }
| USING '(' column_list ')'
  { $$ = JoinCondition{Using: $3} }

join_condition_opt:
%prec JOIN
  { $$ = JoinCondition{} }
| join_condition
  { $$ = $1 }

on_expression_opt:
%prec JOIN
  { $$ = JoinCondition{} }
| ON expression
  { $$ = JoinCondition{On: $2} }

as_opt:
  { $$ = struct{}{} }
| AS
  { $$ = struct{}{} }

table_alias:
  table_id
| column_name_safe_reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }
| STRING
  {
    $$ = NewTableIdent(string($1))
  }

inner_join:
  JOIN
  {
    $$ = JoinStr
  }
| INNER JOIN
  {
    $$ = JoinStr
  }
| CROSS JOIN
  {
    $$ = JoinStr
  }

straight_join:
  STRAIGHT_JOIN
  {
    $$ = StraightJoinStr
  }

outer_join:
  LEFT JOIN
  {
    $$ = LeftJoinStr
  }
| LEFT OUTER JOIN
  {
    $$ = LeftJoinStr
  }
| RIGHT JOIN
  {
    $$ = RightJoinStr
  }
| RIGHT OUTER JOIN
  {
    $$ = RightJoinStr
  }

natural_join:
 NATURAL JOIN
  {
    $$ = NaturalJoinStr
  }
| NATURAL outer_join
  {
    if $2 == LeftJoinStr {
      $$ = NaturalLeftJoinStr
    } else {
      $$ = NaturalRightJoinStr
    }
  }

trigger_name:
  sql_id
  {
    $$ = TriggerName{Name: $1}
  }
| table_id '.' sql_id
  {
    $$ = TriggerName{Qualifier: $1, Name: $3}
  }

load_into_table_name:
  INTO TABLE table_name
  {
    $$ = $3
  }

into_table_name:
  INTO table_name
  {
    $$ = $2
  }
| table_name
  {
    $$ = $1
  }

table_name:
  table_id
  {
    $$ = TableName{Name: $1}
  }
| table_id '.' reserved_table_id
  {
    $$ = TableName{Qualifier: $1, Name: $3}
  }
| table_id '.' table_id '.' reserved_table_id
  {
    $$ = TableName{Qualifier: $1, Schema: $3, Name: $5}
  }

procedure_name:
  sql_id
  {
    $$ = ProcedureName{Name: $1}
  }
| table_id '.' sql_id
  {
    $$ = ProcedureName{Qualifier: $1, Name: $3}
  }

delete_table_name:
table_id '.' '*'
  {
    $$ = TableName{Name: $1}
  }

index_hint_list:
  {
    $$ = nil
  }
| USE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: UseStr, Indexes: $4}
  }
| IGNORE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: IgnoreStr, Indexes: $4}
  }
| FORCE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: ForceStr, Indexes: $4}
  }

where_expression_opt:
  {
    $$ = nil
  }
| WHERE expression
  {
    $$ = $2
  }

expression:
  condition
  {
    $$ = $1
  }
| expression AND expression
  {
    $$ = &AndExpr{Left: $1, Right: $3}
  }
| expression OR expression
  {
    $$ = &OrExpr{Left: $1, Right: $3}
  }
| NOT expression
  {
    $$ = &NotExpr{Expr: $2}
  }
| expression IS is_suffix
  {
    $$ = &IsExpr{Operator: $3, Expr: $1}
  }
| value_expression
  {
    $$ = $1
  }
| DEFAULT default_opt
  {
    $$ = &Default{ColName: $2}
  }

default_opt:
  /* empty */
  {
    $$ = ""
  }
| openb ID closeb
  {
    $$ = string($2)
  }

boolean_value:
  TRUE
  {
    $$ = BoolVal(true)
  }
| FALSE
  {
    $$ = BoolVal(false)
  }

condition:
  value_expression compare value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: $2, Right: $3}
  }
| value_expression IN col_tuple
  {
    $$ = &ComparisonExpr{Left: $1, Operator: InStr, Right: $3}
  }
| value_expression NOT IN col_tuple
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotInStr, Right: $4}
  }
| value_expression LIKE value_expression like_escape_opt
  {
    $$ = &ComparisonExpr{Left: $1, Operator: LikeStr, Right: $3, Escape: $4}
  }
| value_expression NOT LIKE value_expression like_escape_opt
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotLikeStr, Right: $4, Escape: $5}
  }
| value_expression REGEXP value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: RegexpStr, Right: $3}
  }
| value_expression NOT REGEXP value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotRegexpStr, Right: $4}
  }
| value_expression BETWEEN value_expression AND value_expression
  {
    $$ = &RangeCond{Left: $1, Operator: BetweenStr, From: $3, To: $5}
  }
| value_expression NOT BETWEEN value_expression AND value_expression
  {
    $$ = &RangeCond{Left: $1, Operator: NotBetweenStr, From: $4, To: $6}
  }
| EXISTS subquery
  {
    $$ = &ExistsExpr{Subquery: $2}
  }

is_suffix:
  NULL
  {
    $$ = IsNullStr
  }
| NOT NULL
  {
    $$ = IsNotNullStr
  }
| TRUE
  {
    $$ = IsTrueStr
  }
| NOT TRUE
  {
    $$ = IsNotTrueStr
  }
| FALSE
  {
    $$ = IsFalseStr
  }
| NOT FALSE
  {
    $$ = IsNotFalseStr
  }

compare:
  '='
  {
    $$ = EqualStr
  }
| '<'
  {
    $$ = LessThanStr
  }
| '>'
  {
    $$ = GreaterThanStr
  }
| LE
  {
    $$ = LessEqualStr
  }
| GE
  {
    $$ = GreaterEqualStr
  }
| NE
  {
    $$ = NotEqualStr
  }
| NULL_SAFE_EQUAL
  {
    $$ = NullSafeEqualStr
  }

like_escape_opt:
  {
    $$ = nil
  }
| ESCAPE value_expression
  {
    $$ = $2
  }

col_tuple:
  row_tuple
  {
    $$ = $1
  }
| subquery
  {
    $$ = $1
  }
| LIST_ARG
  {
    $$ = ListArg($1)
  }

subquery:
  openb select_statement closeb
  {
    $$ = &Subquery{Select: $2}
  }

subquery_or_values:
  subquery
  {
    $$ = $1
  }
| openb values_statement closeb
  {
    $$ = $2
  }


argument_expression_list_opt:
  {
    $$ = nil
  }
| argument_expression_list

argument_expression_list:
  argument_expression
  {
    $$ = SelectExprs{$1}
  }
| argument_expression_list ',' argument_expression
  {
    $$ = append($1, $3)
  }

expression_list:
  expression
  {
    $$ = Exprs{$1}
  }
| expression_list ',' expression
  {
    $$ = append($1, $3)
  }

value_expression:
  value
  {
    $$ = $1
  }
| column_name_safe_reserved_keyword
  {
    $$ = &ColName{Name: NewColIdent(string($1))}
  }
| boolean_value
  {
    $$ = $1
  }
| column_name
  {
    $$ = $1
  }
| tuple_expression
  {
    $$ = $1
  }
| subquery
  {
    $$ = $1
  }
| value_expression '&' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitAndStr, Right: $3}
  }
| value_expression '|' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitOrStr, Right: $3}
  }
| value_expression '^' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitXorStr, Right: $3}
  }
| value_expression '+' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: PlusStr, Right: $3}
  }
| value_expression '-' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: MinusStr, Right: $3}
  }
| value_expression '*' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: MultStr, Right: $3}
  }
| value_expression '/' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: DivStr, Right: $3}
  }
| value_expression DIV value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: IntDivStr, Right: $3}
  }
| value_expression '%' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ModStr, Right: $3}
  }
| value_expression MOD value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ModStr, Right: $3}
  }
| value_expression SHIFT_LEFT value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ShiftLeftStr, Right: $3}
  }
| value_expression SHIFT_RIGHT value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ShiftRightStr, Right: $3}
  }
| column_name JSON_EXTRACT_OP value
  {
    $$ = &BinaryExpr{Left: $1, Operator: JSONExtractOp, Right: $3}
  }
| column_name JSON_UNQUOTE_EXTRACT_OP value
  {
    $$ = &BinaryExpr{Left: $1, Operator: JSONUnquoteExtractOp, Right: $3}
  }
| value_expression COLLATE charset
  {
    $$ = &CollateExpr{Expr: $1, Charset: $3}
  }
| BINARY value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: BinaryStr, Expr: $2}
  }
| UNDERSCORE_BINARY value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: UBinaryStr, Expr: $2}
  }
| UNDERSCORE_UTF8MB4 value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: Utf8mb4Str, Expr: $2}
  }
| '+'  value_expression %prec UNARY
  {
    if num, ok := $2.(*SQLVal); ok && num.Type == IntVal {
      $$ = num
    } else {
      $$ = &UnaryExpr{Operator: UPlusStr, Expr: $2}
    }
  }
| '-'  value_expression %prec UNARY
  {
    if num, ok := $2.(*SQLVal); ok && num.Type == IntVal {
      // Handle double negative
      if num.Val[0] == '-' {
        num.Val = num.Val[1:]
        $$ = num
      } else {
        $$ = NewIntVal(append([]byte("-"), num.Val...))
      }
    } else {
      $$ = &UnaryExpr{Operator: UMinusStr, Expr: $2}
    }
  }
| '~'  value_expression
  {
    $$ = &UnaryExpr{Operator: TildaStr, Expr: $2}
  }
| '!' value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: BangStr, Expr: $2}
  }
| INTERVAL value_expression sql_id
  {
    // This rule prevents the usage of INTERVAL
    // as a function. If support is needed for that,
    // we'll need to revisit this. The solution
    // will be non-trivial because of grammar conflicts.
    $$ = &IntervalExpr{Expr: $2, Unit: $3.String()}
  }
| function_call_generic
| function_call_keyword
| function_call_nonkeyword
| function_call_conflict
| function_call_window
| function_call_aggregate_with_window

/*
  Regular function calls without special token or syntax, guaranteed to not
  introduce side effects due to being a simple identifier
*/
function_call_generic:
  sql_id openb distinct_opt argument_expression_list_opt closeb
  {
    $$ = &FuncExpr{Name: $1, Distinct: $3 == DistinctStr, Exprs: $4}
  }
| table_id '.' reserved_sql_id openb argument_expression_list_opt closeb
  {
    $$ = &FuncExpr{Qualifier: $1, Name: $3, Exprs: $5}
  }

/*
   Special aggregate function calls that can't be treated like a normal function call, because they have an optional
   OVER clause (not legal on any other non-window, non-aggregate function)
 */
function_call_aggregate_with_window:
 MAX openb distinct_opt argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $4, Distinct: $3 == DistinctStr, Over: $6}
  }
| AVG openb distinct_opt argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $4, Distinct: $3 == DistinctStr, Over: $6}
  }
| BIT_AND openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| BIT_OR openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| BIT_XOR openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| COUNT openb distinct_opt argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $4, Distinct: $3 == DistinctStr, Over: $6}
  }
| JSON_ARRAYAGG openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| JSON_OBJECTAGG openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| MIN openb distinct_opt argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $4, Distinct: $3 == DistinctStr, Over: $6}
  }
| STDDEV_POP openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| STDDEV openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| STD openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| STDDEV_SAMP openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| SUM openb distinct_opt argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $4, Distinct: $3 == DistinctStr, Over: $6}
  }
| VAR_POP openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| VARIANCE openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| VAR_SAMP openb argument_expression_list closeb over_opt
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }

/*
  Function calls with an OVER expression, only valid for certain aggregate and window functions
*/
function_call_window:
  CUME_DIST openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }
| DENSE_RANK openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }
| FIRST_VALUE openb argument_expression closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: SelectExprs{$3}, Over: $5}
  }
| LAG openb argument_expression_list closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| LAST_VALUE openb argument_expression closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: SelectExprs{$3}, Over: $5}
  }
| LEAD openb argument_expression_list closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| NTH_VALUE openb argument_expression_list closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3, Over: $5}
  }
| NTILE openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }
| PERCENT_RANK openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }
| RANK openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }
| ROW_NUMBER openb closeb over
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Over: $4}
  }

/*
  Function calls using reserved keywords, with dedicated grammar rules
  as a result
  TODO: some of these change the case or even the name of the function expression. Should be preserved.
*/
function_call_keyword:
  LEFT openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| RIGHT openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| FORMAT openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| SCHEMA openb closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1))}
  }
| CONVERT openb expression ',' convert_type closeb
  {
    $$ = &ConvertExpr{Expr: $3, Type: $5}
  }
| CAST openb expression AS convert_type closeb
  {
    $$ = &ConvertExpr{Expr: $3, Type: $5}
  }
| CONVERT openb expression USING charset closeb
  {
    $$ = &ConvertUsingExpr{Expr: $3, Type: $5}
  }
| SUBSTR openb column_name FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| SUBSTRING openb column_name FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| SUBSTR openb STRING FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{StrVal: NewStrVal($3), From: $5, To: $7}
  }
| SUBSTRING openb STRING FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{StrVal: NewStrVal($3), From: $5, To: $7}
  }
| TRIM openb value_expression closeb
  {
    $$ = &TrimExpr{Pattern: NewStrVal([]byte(" ")), Str: $3, Dir: Both}
  }
| TRIM openb value_expression FROM value_expression closeb
  {
    $$ = &TrimExpr{Pattern: $3, Str: $5, Dir: Both}
  }
| TRIM openb LEADING value_expression FROM value_expression closeb
  {
    $$ = &TrimExpr{Pattern: $4, Str: $6, Dir: Leading}
  }
| TRIM openb TRAILING value_expression FROM value_expression closeb
  {
    $$ = &TrimExpr{Pattern: $4, Str: $6, Dir: Trailing}
  }
| TRIM openb BOTH value_expression FROM value_expression closeb
  {
    $$ = &TrimExpr{Pattern: $4, Str: $6, Dir: Both}
  }
| MATCH openb argument_expression_list closeb AGAINST openb value_expression match_option closeb
  {
  $$ = &MatchExpr{Columns: $3, Expr: $7, Option: $8}
  }
| FIRST openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| GROUP_CONCAT openb distinct_opt argument_expression_list order_by_opt separator_opt closeb
  {
    $$ = &GroupConcatExpr{Distinct: $3, Exprs: $4, OrderBy: $5, Separator: $6}
  }
| CASE expression_opt when_expression_list else_expression_opt END
  {
    $$ = &CaseExpr{Expr: $2, Whens: $3, Else: $4}
  }
| VALUES openb column_name closeb
  {
    $$ = &ValuesFuncExpr{Name: $3}
  }

/*
  Function calls using non reserved keywords but with special syntax forms.
  Dedicated grammar rules are needed because of the special syntax
*/
function_call_nonkeyword:
  CURRENT_TIMESTAMP func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
| UTC_TIMESTAMP func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
| UTC_TIME func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
/* doesn't support fsp */
| UTC_DATE func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
  // now
| LOCALTIME func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
  // now
| LOCALTIMESTAMP func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
  // curdate
/* doesn't support fsp */
| CURRENT_DATE func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
  // curtime
| CURRENT_TIME func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
| CURRENT_USER func_parens_opt
  {
    $$ = &FuncExpr{Name:NewColIdent(string($1))}
  }
// these functions can also be called with an optional argument
| CURRENT_TIMESTAMP func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
| UTC_TIMESTAMP func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
| UTC_TIME func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
  // now
| LOCALTIME func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
  // now
| LOCALTIMESTAMP func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
  // curtime
| CURRENT_TIME func_datetime_precision
  {
    $$ = &CurTimeFuncExpr{Name:NewColIdent(string($1)), Fsp:$2}
  }
| TIMESTAMPADD openb sql_id ',' value_expression ',' value_expression closeb
  {
    $$ = &TimestampFuncExpr{Name:string("timestampadd"), Unit:$3.String(), Expr1:$5, Expr2:$7}
  }
| TIMESTAMPDIFF openb sql_id ',' value_expression ',' value_expression closeb
  {
    $$ = &TimestampFuncExpr{Name:string("timestampdiff"), Unit:$3.String(), Expr1:$5, Expr2:$7}
  }

// Optional parens for certain keyword functions that don't require them.
func_parens_opt:
  /* empty */
| openb closeb

func_datetime_precision:
  openb value_expression closeb
  {
    $$ = $2
  }

/*
  Function calls using non reserved keywords with *normal* syntax forms. Because
  the names are non-reserved, they need a dedicated rule so as not to conflict
*/
function_call_conflict:
  IF openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| DATABASE openb argument_expression_list_opt closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| MOD openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| REPLACE openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| SUBSTR openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }
| SUBSTRING openb argument_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent(string($1)), Exprs: $3}
  }

match_option:
/*empty*/
  {
    $$ = ""
  }
| IN BOOLEAN MODE
  {
    $$ = BooleanModeStr
  }
| IN NATURAL LANGUAGE MODE
 {
    $$ = NaturalLanguageModeStr
 }
| IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION
 {
    $$ = NaturalLanguageModeWithQueryExpansionStr
 }
| WITH QUERY EXPANSION
 {
    $$ = QueryExpansionStr
 }

charset:
  ID
{
    $$ = string($1)
}
| STRING
{
    $$ = string($1)
}

convert_type:
  BINARY length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| CHAR length_opt charset_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2, Charset: $3, Operator: CharacterSetStr}
  }
| CHAR length_opt ID
  {
    $$ = &ConvertType{Type: string($1), Length: $2, Charset: string($3)}
  }
| DATE
  {
    $$ = &ConvertType{Type: string($1)}
  }
| DATETIME length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| DECIMAL decimal_length_opt
  {
    $$ = &ConvertType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| JSON
  {
    $$ = &ConvertType{Type: string($1)}
  }
| NCHAR length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| SIGNED
  {
    $$ = &ConvertType{Type: string($1)}
  }
| SIGNED INTEGER
  {
    $$ = &ConvertType{Type: string($1)}
  }
| TIME length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| UNSIGNED
  {
    $$ = &ConvertType{Type: string($1)}
  }
| UNSIGNED INTEGER
  {
    $$ = &ConvertType{Type: string($1)}
  }

expression_opt:
  {
    $$ = nil
  }
| expression
  {
    $$ = $1
  }

separator_opt:
  {
    $$ = string("")
  }
| SEPARATOR STRING
  {
    $$ = string($2)
  }

when_expression_list:
  when_expression
  {
    $$ = []*When{$1}
  }
| when_expression_list when_expression
  {
    $$ = append($1, $2)
  }

when_expression:
  WHEN expression THEN expression
  {
    $$ = &When{Cond: $2, Val: $4}
  }

else_expression_opt:
  {
    $$ = nil
  }
| ELSE expression
  {
    $$ = $2
  }

column_name:
  sql_id
  {
    $$ = &ColName{Name: $1}
  }
| table_id '.' reserved_sql_id
  {
    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: $3}
  }
| table_id '.' reserved_table_id '.' reserved_sql_id
  {
    $$ = &ColName{Qualifier: TableName{Qualifier: $1, Name: $3}, Name: $5}
  }

value:
  STRING
  {
    $$ = NewStrVal($1)
  }
| HEX
  {
    $$ = NewHexVal($1)
  }
| BIT_LITERAL
  {
    $$ = NewBitVal($1)
  }
| INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| FLOAT
  {
    $$ = NewFloatVal($1)
  }
| HEXNUM
  {
    $$ = NewHexNum($1)
  }
| VALUE_ARG
  {
    $$ = NewValArg($1)
  }
| NULL
  {
    $$ = &NullVal{}
  }

num_val:
  VALUE
  {
    $$ = NewIntVal([]byte("1"))
  }
| INTEGRAL VALUES
  {
    $$ = NewIntVal($1)
  }
| VALUE_ARG VALUES
  {
    $$ = NewValArg($1)
  }

group_by_opt:
  {
    $$ = nil
  }
| GROUP BY group_by_list
  {
    $$ = $3
  }

group_by_list:
  group_by
  {
    $$ = Exprs{$1}
  }
| group_by_list ',' group_by
  {
    $$ = append($1, $3)
  }

group_by:
  expression
  {
    $$ = $1
  }

having_opt:
  {
    $$ = nil
  }
| HAVING having
  {
    $$ = $2
  }

having:
  expression
  {
    $$ = $1
  }

order_by_opt:
  {
    $$ = nil
  }
| ORDER BY order_list
  {
    $$ = $3
  }

order_list:
  order
  {
    $$ = OrderBy{$1}
  }
| order_list ',' order
  {
    $$ = append($1, $3)
  }

order:
  expression asc_desc_opt
  {
    $$ = &Order{Expr: $1, Direction: $2}
  }

asc_desc_opt:
  {
    $$ = AscScr
  }
| ASC
  {
    $$ = AscScr
  }
| DESC
  {
    $$ = DescScr
  }

limit_opt:
  {
    $$ = nil
  }
| LIMIT integral_or_value_arg
  {
    $$ = &Limit{Rowcount: $2}
  }
| LIMIT integral_or_value_arg ',' integral_or_value_arg
  {
    $$ = &Limit{Offset: $2, Rowcount: $4}
  }
| LIMIT integral_or_value_arg OFFSET integral_or_value_arg
  {
    $$ = &Limit{Offset: $4, Rowcount: $2}
  }

integral_or_value_arg:
INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| VALUE_ARG
  {
    $$ = NewValArg($1)
  }

lock_opt:
  {
    $$ = ""
  }
| FOR UPDATE
  {
    $$ = ForUpdateStr
  }
| LOCK IN SHARE MODE
  {
    $$ = ShareModeStr
  }

// insert_data expands all combinations into a single rule.
// This avoids a shift/reduce conflict while encountering the
// following two possible constructs:
// insert into t1(a, b) (select * from t2)
// insert into t1(select * from t2)
// Because the rules are together, the parser can keep shifting
// the tokens until it disambiguates a as sql_id and select as keyword.
insert_data:
  VALUES tuple_list
  {
    $$ = &Insert{Rows: $2}
  }
| openb closeb VALUES tuple_list
  {
    $$ = &Insert{Columns: []ColIdent{}, Rows: $4}
  }
| select_statement
  {
    $$ = &Insert{Rows: $1}
  }
| openb select_statement closeb
  {
    // Drop the redundant parenthesis.
    $$ = &Insert{Rows: $2}
  }
| openb ins_column_list closeb VALUES tuple_list
  {
    $$ = &Insert{Columns: $2, Rows: $5}
  }
| openb ins_column_list closeb select_statement
  {
    $$ = &Insert{Columns: $2, Rows: $4}
  }
| openb ins_column_list closeb openb select_statement closeb
  {
    // Drop the redundant parenthesis.
    $$ = &Insert{Columns: $2, Rows: $5}
  }

ins_column_list_opt:
  {
    $$ = nil
  }
| openb ins_column_list closeb
  {
    $$ = $2
  }

ins_column_list:
  reserved_sql_id
  {
    $$ = Columns{$1}
  }
| reserved_sql_id '.' reserved_sql_id
  {
    $$ = Columns{$3}
  }
| ins_column_list ',' reserved_sql_id
  {
    $$ = append($$, $3)
  }
| ins_column_list ',' reserved_sql_id '.' reserved_sql_id
  {
    $$ = append($$, $5)
  }

on_dup_opt:
  {
    $$ = nil
  }
| ON DUPLICATE KEY UPDATE assignment_list
  {
    $$ = $5
  }

tuple_list:
  tuple_or_empty
  {
    $$ = Values{$1}
  }
| tuple_list ',' tuple_or_empty
  {
    $$ = append($1, $3)
  }

tuple_or_empty:
  row_tuple
  {
    $$ = $1
  }
| openb closeb
  {
    $$ = ValTuple{}
  }

row_tuple:
  openb expression_list closeb
  {
    $$ = ValTuple($2)
  }

tuple_expression:
  row_tuple
  {
    if len($1) == 1 {
      $$ = &ParenExpr{$1[0]}
    } else {
      $$ = $1
    }
  }

assignment_list:
  assignment_expression
  {
    $$ = AssignmentExprs{$1}
  }
| assignment_list ',' assignment_expression
  {
    $$ = append($1, $3)
  }

assignment_expression:
  column_name '=' expression
  {
    $$ = &AssignmentExpr{Name: $1, Expr: $3}
  }
| reserved_keyword '=' expression {
    $$ = &AssignmentExpr{Name: &ColName{Name: NewColIdent(string($1))}, Expr: $3}
  }

set_list:
  set_expression
  {
    $$ = SetVarExprs{$1}
  }
| set_list ',' set_expression
  {
    $$ = append($1, $3)
  }

set_expression:
  set_expression_assignment
  {
    colName, scope, err := VarScopeForColName($1.Name)
    if err != nil {
      yylex.Error(err.Error())
      return 1
    }
    $1.Name = colName
    $1.Scope = scope
    $$ = $1
  }
| set_scope_primary set_expression_assignment
  {
    _, scope, err := VarScopeForColName($2.Name)
    if err != nil {
      yylex.Error(err.Error())
      return 1
    } else if scope != SetScope_None {
      yylex.Error(fmt.Sprintf("invalid system variable name `%s`", $2.Name.Name.val))
      return 1
    }
    $2.Scope = $1
    $$ = $2
  }
| set_scope_secondary set_expression_assignment
  {
    _, scope, err := VarScopeForColName($2.Name)
    if err != nil {
      yylex.Error(err.Error())
      return 1
    } else if scope != SetScope_None {
      yylex.Error(fmt.Sprintf("invalid system variable name `%s`", $2.Name.Name.val))
      return 1
    }
    $2.Scope = $1
    $$ = $2
  }
| charset_or_character_set charset_value collate_opt
  {
    $$ = &SetVarExpr{Name: NewColName(string($1)), Expr: $2, Scope: SetScope_Session}
  }

set_scope_primary:
  GLOBAL
  {
    $$ = SetScope_Global
  }
| SESSION
  {
    $$ = SetScope_Session
  }

set_scope_secondary:
  LOCAL
  {
    $$ = SetScope_Session
  }
| PERSIST
  {
    $$ = SetScope_Persist
  }
| PERSIST_ONLY
  {
    $$ = SetScope_PersistOnly
  }

set_expression_assignment:
  column_name '=' ON
  {
    $$ = &SetVarExpr{Name: $1, Expr: NewStrVal($3), Scope: SetScope_None}
  }
| column_name '=' OFF
  {
    $$ = &SetVarExpr{Name: $1, Expr: NewStrVal($3), Scope: SetScope_None}
  }
| column_name '=' expression
  {
    $$ = &SetVarExpr{Name: $1, Expr: $3, Scope: SetScope_None}
  }

charset_or_character_set:
  CHARSET
| CHARACTER SET
  {
    $$ = []byte("charset")
  }
| NAMES

charset_value:
  sql_id
  {
    $$ = NewStrVal([]byte($1.String()))
  }
| STRING
  {
    $$ = NewStrVal($1)
  }
| DEFAULT
  {
    $$ = &Default{}
  }

for_from:
  FOR
| FROM

temp_opt:
  { $$ = 0 }
| TEMPORARY
  { $$ = 1 }

exists_opt:
  { $$ = 0 }
| IF EXISTS
  { $$ = 1 }

not_exists_opt:
  { $$ = 0 }
| IF NOT EXISTS
  { $$ = 1 }

ignore_opt:
  { $$ = "" }
| IGNORE
  { $$ = IgnoreStr }

ignore_number_opt:
  { $$ = nil }
| IGNORE INTEGRAL LINES
  { $$ = NewIntVal($2) }

to_or_as:
  TO
  { $$ = struct{}{} }
| AS
  { $$ = struct{}{} }

to_opt:
  { $$ = struct{}{} }
| TO
  { $$ = struct{}{} }
| AS
  { $$ = struct{}{} }

key_type:
  UNIQUE
  { $$ = UniqueStr }
| FULLTEXT
  { $$ = FulltextStr }
| SPATIAL
  { $$ = SpatialStr }

key_type_opt:
  { $$ = "" }
| key_type
  { $$ = $1 }

using_opt:
  { $$ = ColIdent{} }
| USING sql_id
  { $$ = $2 }

sql_id:
  ID
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }

reserved_sql_id_list:
  reserved_sql_id
  {
    $$ = []ColIdent{$1}
  }
| reserved_sql_id_list ',' reserved_sql_id
  {
    $$ = append($$, $3)
  }

reserved_sql_id:
  sql_id
| reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }

table_id:
  ID
  {
    $$ = NewTableIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }

reserved_table_id:
  table_id
| reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }

infile_opt:
  { $$ = string("") }
| INFILE STRING
  { $$ = string($2)}

local_opt:
  { $$ = BoolVal(false) }
| LOCAL
  { $$ = BoolVal(true) }

enclosed_by_opt:
  {
    $$ = nil
  }
| optionally_opt ENCLOSED BY STRING
  {
    $$ = &EnclosedBy{Optionally: $1, Delim: NewStrVal($4)}
  }

optionally_opt:
  {
    $$ = BoolVal(false)
  }
| OPTIONALLY
  {
    $$ = BoolVal(true)
  }

terminated_by_opt:
  {
    $$ = nil
  }
| TERMINATED BY STRING
  {
    $$ = NewStrVal($3)
  }

escaped_by_opt:
  {
    $$ = nil
  }
| ESCAPED BY STRING
  {
    $$ = NewStrVal($3)
  }

fields_opt:
  {
    $$ = nil
  }
| columns_or_fields terminated_by_opt enclosed_by_opt escaped_by_opt
  {
    $$ = &Fields{TerminatedBy: $2, EnclosedBy: $3, EscapedBy: $4}
  }

lines_opt:
  {
    $$ = nil
  }
| LINES starting_by_opt terminated_by_opt
  {
    $$ = &Lines{StartingBy: $2, TerminatedBy: $3}
  }

starting_by_opt:
  {
    $$ = nil
  }
| STARTING BY STRING
  {
    $$ = NewStrVal($3)
  }

lock_statement:
  LOCK TABLES lock_table_list
  {
    $$ = &LockTables{Tables: $3}
  }

lock_table_list:
  lock_table
  {
    $$ = TableAndLockTypes{$1}
  }
| lock_table_list ',' lock_table
  {
    $$ = append($1, $3)
  }

lock_table:
  table_name lock_type
  {
    $$ = &TableAndLockType{Table:&AliasedTableExpr{Expr: $1}, Lock:$2}
  }
|  table_name AS table_alias lock_type
  {
    $$ = &TableAndLockType{Table:&AliasedTableExpr{Expr: $1, As: $3}, Lock:$4}
  }

lock_type:
  READ
  {
    $$ = LockRead
  }
| READ LOCAL
  {
    $$ = LockReadLocal
  }
| WRITE
  {
    $$ = LockWrite
  }
| LOW_PRIORITY WRITE
  {
    $$ = LockLowPriorityWrite
  }

unlock_statement:
  UNLOCK TABLES
  {
    $$ = &UnlockTables{}
  }

kill_statement:
  KILL INTEGRAL
  {
    $$ = &Kill{Connection: true, ConnID: NewIntVal($2)}
  }
|  KILL QUERY INTEGRAL
  {
    $$ = &Kill{ConnID: NewIntVal($3)}
  }
| KILL CONNECTION INTEGRAL
  {
    $$ = &Kill{Connection: true, ConnID: NewIntVal($3)}
  }

/*
  These are not all necessarily reserved in MySQL, but some are.

  These are more importantly reserved because they may conflict with our grammar.
  If you want to move one that is not reserved in MySQL (i.e. ESCAPE) to the
  non_reserved_keywords, you'll need to deal with any conflicts.

  Sorted alphabetically
*/
reserved_keyword:
  ACCOUNT
| ADD
| AFTER // TODO: this is not reserved in MySQL, why is it here?
| ALTER
| AND
| ARRAY
| AS
| ASC
| ATTRIBUTE
| AUTO_INCREMENT
| AVG
| BETWEEN
| BINARY
| BIT_AND
| BIT_OR
| BIT_XOR
| BY
| CALL
| CASE
| COLLATE
| COMMENT_KEYWORD
| CONVERT
| CONNECTION
| COUNT
| CREATE
| CROSS
| CURRENT
| CURRENT_DATE
| CURRENT_TIME
| CURRENT_TIMESTAMP
| DATABASE
| DATABASES
| DEFAULT
| DELETE
| DESC
| DESCRIBE
| DETERMINISTIC
| DISTINCT
| DIV
| DROP
| ELSE
| ELSEIF
| END
| ERRORS
| ESCAPE
| EVENT
| EXECUTE
| EXISTS
| EXPLAIN
| FAILED_LOGIN_ATTEMPTS
| FALSE
| FILE
| FIRST
| FOLLOWING
| FOLLOWS
| FOR
| FORCE
| FORMAT
| FOUND
| FROM
| FULL
| FUNCTION
| GENERATED
| GRANT
| GROUP
| GROUPING
| GROUPS
| HANDLER
| HAVING
| IDENTIFIED
| IF
| IGNORE
| IN
| INOUT
| INDEX
| INNER
| INSERT
| INTERVAL
| INTO
| IS
| JOIN
| JSON_ARRAYAGG
| JSON_OBJECTAGG
| JSON_TABLE
| KEY
| KILL
| LATERAL
| LEFT
| LIKE
| LIMIT
| LOCALTIME
| LOCALTIMESTAMP
| LOCK
| MATCH
| MAX
| MAXVALUE
| MEMBER
| MIN
| MOD
| MODIFIES
| NATURAL
| NEXT // next should be doable as non-reserved, but is not due to the special `select next num_val` query that vitess supports
| NONE
| NOT
| NULL
| NVAR
| OF
| OFF
| ON
| OPTIMIZER_COSTS
| OR
| ORDER
| OUT
| OUTER
| OVER
| PASSWORD
| PASSWORD_LOCK
| PASSWORD_LOCK_TIME
| PROCEDURE
| PROCESS
| READS
| RECURSIVE
| REFERENCES
| REGEXP
| RELOAD
| RENAME
| REPLACE
| REQUIRE
| REVOKE
| RIGHT
| SCHEMA
| SELECT
| SEPARATOR
| SET
| SHOW
| SHUTDOWN
| SQL
| STATUS
| STD
| STDDEV
| STDDEV_POP
| STDDEV_SAMP
| STORED
| STRAIGHT_JOIN
| SUBSTR
| SUBSTRING
| SUM
| SUPER
| SYSTEM
| TABLE
| THEN
| TIMESTAMPADD
| TIMESTAMPDIFF
| TO
| TRIGGER
| TRUE
| UNION
| UNIQUE
| UNLOCK
| UPDATE
| USAGE
| USE
| USING
| UTC_DATE
| UTC_TIME
| UTC_TIMESTAMP
| VALUES
| VALUE
| VARIANCE
| VAR_POP
| VAR_SAMP
| VIRTUAL
| WHEN
| WHERE
| WINDOW
| WITH

/*
  These are non-reserved Vitess, because they don't cause conflicts in the grammar.
  Some of them may be reserved in MySQL. The good news is we backtick quote them
  when we rewrite the query, so no issue should arise.

  Sorted alphabetically
*/
non_reserved_keyword:
  ACTION
| ACTIVE
| ADMIN
| AGAINST
| ALWAYS
| AUTHENTICATION
| BEFORE // TODO: this (and some others) should be reserved
| BEGIN
| BIGINT
| SERIAL
| BIT
| BLOB
| BOOL
| BOOLEAN
| BUCKETS
| CASCADE
| CATALOG_NAME
| CHANGE
| CHANNEL
| CHAR
| CHARACTER
| CHARSET
| CHECK
| CIPHER
| CLASS_ORIGIN
| CLIENT
| CLONE
| COLLATION
| COLUMNS
| COLUMN_NAME
| COMMIT
| COMMITTED
| COMPONENT
| CONSTRAINT
| CONSTRAINT_CATALOG
| CONSTRAINT_NAME
| CONSTRAINT_SCHEMA
| CONTAINS
| CURSOR_NAME
| DATA
| DATE
| DATETIME
| DAY
| DECIMAL
| DECLARE
| DEFINER
| DEFINITION
| DESCRIPTION
| DISABLE
| DOUBLE
| DUPLICATE
| EACH
| ENABLE
| ENCRYPTION
| ENFORCED
| ENGINE
| ENGINES
| ENUM
| ERROR
| EXCEPT
| EXCLUDE
| EXPANSION
| EXPIRE
| FIELDS
| FIXED
| FLOAT_TYPE
| FLUSH
| FOREIGN
| FULLTEXT
| GENERAL
| GEOMCOLLECTION
| GEOMETRY
| GEOMETRYCOLLECTION
| GET_MASTER_PUBLIC_KEY
| GLOBAL
| GRANTS
| HOSTS
| HISTOGRAM
| HISTORY
| INACTIVE
| INDEXES
| INITIAL
| INT
| INTEGER
| INVISIBLE
| INVOKER
| ISOLATION
| ISSUER
| JSON
| KEYS
| KEY_BLOCK_SIZE
| LANGUAGE
| LAST_INSERT_ID
| LESS
| LEVEL
| LINES
| LINESTRING
| LOAD
| LOCAL
| LOCKED
| LOGS
| LONGBLOB
| LONGTEXT
| LOW_PRIORITY
| MASTER_COMPRESSION_ALGORITHMS
| MASTER_PUBLIC_KEY_PATH
| MASTER_TLS_CIPHERSUITES
| MASTER_ZSTD_COMPRESSION_LEVEL
| MAX_CONNECTIONS_PER_HOUR
| MAX_QUERIES_PER_HOUR
| MAX_UPDATES_PER_HOUR
| MAX_USER_CONNECTIONS
| MEDIUMBLOB
| MEDIUMINT
| MEDIUMTEXT
| MESSAGE_TEXT
| MODE
| MODIFY
| MULTILINESTRING
| MULTIPOINT
| MULTIPOLYGON
| MYSQL_ERRNO
| NAMES
| NATIONAL
| NCHAR
| NESTED
| NETWORK_NAMESPACE
| NEVER
| NO
| NOWAIT
| NULLS
| NUMERIC
| OFFSET
| OJ
| OLD
| ONLY
| OPTIMIZE
| OPTION
| OPTIONAL
| OPTIONALLY
| ORDINALITY
| ORGANIZATION
| OTHERS
| PARTITION
| PATH
| PERSIST
| PERSIST_ONLY
| PLUGINS
| POINT
| POLYGON
| PRECEDES
| PRECEDING
| PRECISION
| PRIMARY
| PRIVILEGE_CHECKS_USER
| PRIVILEGES
| PROCESSLIST
| PROXY
| QUERY
| RANDOM
| RANGE
| READ
| REAL
| REFERENCE
| RELAY
| RELEASE
| REORGANIZE
| REPAIR
| REPEATABLE
| REPLICATION
| REQUIRE_ROW_FORMAT
| RESIGNAL
| RESOURCE
| RESPECT
| RESTART
| RESTRICT
| RETAIN
| REUSE
| ROLE
| ROLLBACK
| ROUTINE
| ROWS
| SAVEPOINT
| SCHEMAS
| SCHEMA_NAME
| SECONDARY
| SECONDARY_ENGINE
| SECONDARY_LOAD
| SECONDARY_UNLOAD
| SECURITY
| SEQUENCE
| SERIALIZABLE
| SESSION
| SHARE
| SIGNAL
| SIGNED
| SKIP
| SLAVE
| SLOW
| SMALLINT
| SPATIAL
| SQLSTATE
| SRID
| SSL
| START
| STARTING
| STREAM
| SUBCLASS_ORIGIN
| SUBJECT
| TABLES
| TABLESPACE
| TABLE_NAME
| TEMPORARY
| TEXT
| THAN
| THREAD_PRIORITY
| TIES
| TIME
| TIMESTAMP
| TINYBLOB
| TINYINT
| TINYTEXT
| TRANSACTION
| TRIGGERS
| TRUNCATE
| UNBOUNDED
| UNCOMMITTED
| UNSIGNED
| UNUSED
| USER
| USER_RESOURCES
| VARBINARY
| VARCHAR
| VARIABLES
| VARYING
| VCPU
| VIEW
| VISIBLE
| WARNINGS
| WORK
| WRITE
| X509
| YEAR
| ZEROFILL

// Reserved keywords that cause grammar conflicts in some places, but are safe to use as column name / alias identifiers.
// These keywords should also go in reserved_keyword.
// TODO: The ones commented out here cause shift/reduce conflicts but need to be column name safe
column_name_safe_reserved_keyword:
  ACCOUNT
| AFTER
| ATTRIBUTE
| AUTO_INCREMENT
| AVG
| BIT_AND
| BIT_OR
| BIT_XOR
| CONNECTION
| COUNT
| CUME_DIST
| CURRENT
| DENSE_RANK
| END
| ERRORS
//| ESCAPE
| EVENT
| EXECUTE
| FAILED_LOGIN_ATTEMPTS
| FILE
| FIRST
| FIRST_VALUE
| FOLLOWING
| FOLLOWS
| FORMAT
| FOUND
| FULL
| HANDLER
| IDENTIFIED
| JSON_ARRAYAGG
| JSON_OBJECTAGG
| LAG
| LAST_VALUE
| LEAD
| MAX
| MIN
//| NEXT
| NONE
| NTH_VALUE
| NTILE
| NVAR
//| NVARCHAR
//| OFF
| PASSWORD
| PASSWORD_LOCK
| PASSWORD_LOCK_TIME
| PERCENT_RANK
| PROCESS
| RANK
| RELOAD
| ROW_NUMBER
| SHUTDOWN
//| SQL_CACHE
//| SQL_NO_CACHE
| STATUS
| STD
| STDDEV
| STDDEV_POP
| STDDEV_SAMP
| SUPER
| TIMESTAMPADD
| TIMESTAMPDIFF
| SUM
| VALUE
| VARIANCE
| VAR_POP
| VAR_SAMP
| COMMENT_KEYWORD

openb:
  '('
  {
    if incNesting(yylex) {
      yylex.Error("max nesting level reached")
      return 1
    }
  }

closeb:
  ')'
  {
    decNesting(yylex)
  }
