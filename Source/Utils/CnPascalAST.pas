{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2022 CnPack 开发组                       }
{                   ------------------------------------                       }
{                                                                              }
{            本开发包是开源的自由软件，您可以遵照 CnPack 的发布协议来修        }
{        改和重新发布这一程序。                                                }
{                                                                              }
{            发布这一开发包的目的是希望它有用，但没有任何担保。甚至没有        }
{        适合特定目的而隐含的担保。更详细的情况请参阅 CnPack 发布协议。        }
{                                                                              }
{            您应该已经和开发包一起收到一份 CnPack 发布协议的副本。如果        }
{        还没有，可访问我们的网站：                                            }
{                                                                              }
{            网站地址：http://www.cnpack.org                                   }
{            电子邮件：master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnPascalAST;
{* |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：Pascal 代码抽象语法树生成单元
* 单元作者：刘啸（LiuXiao） liuxiao@cnpack.org; http://www.cnpack.org
* 备    注：同时支持 Unicode 和非 Unicode 编译器
* 开发平台：2022.09.24 V1.0
*               创建单元，离完整实现功能还早
================================================================================
|</PRE>}

interface

{$I CnPack.inc}

uses
  SysUtils, Classes, TypInfo, mPasLex, CnPasWideLex, CnTree, CnContainers;

type
  ECnPascalAstException = class(Exception);

{$IFDEF SUPPORT_WIDECHAR_IDENTIFIER}  // 2005 以上
  TCnGeneralPasLex = TCnPasWideLex;
  TCnGeneralLexBookmark = TCnPasWideBookmark;
{$ELSE}                               // 5 6 7
  TCnGeneralPasLex = TmwPasLex;
  TCnGeneralLexBookmark = TmwPasLexBookmark;
{$ENDIF}

  TCnPasNodeType = (
    cntInvalid,

    cntSpace,
    cntLineComment,
    cntBlockComment,

    cntComma,
    cntSemiColon,
    cntColon,
    cntRelOps,
    cntAddOps,
    cntMulOps,
    cntRange,
    cntHat,
    cntDot,

    cntSquareOpen,
    cntSquareClose,
    cntRoundOpen,
    cntRoundClose,

    cntAssign,

    cntInt,
    cntFloat,
    cntString,
    cntIdent,
    cntGuid,

    cntConst,
    cntIndex,
    cntRead,
    cntWrite,
    cntImplements,
    cntDefault,
    cntStored,
    cntNodefault,
    cntReadonly,
    cntWriteonly,

    cntProgram,
    cntLibrary,
    cntUnit,

    cntUsesClause,
    cntUsesDecl,
    cntTypeSection,
    cntTypeDecl,
    cntTypeKeyword,
    cntTypeID,
    cntRestrictedType,
    cntCommonType,

    cntEnumeratedList,
    cntEmumeratedIdent,
    cntVariantSection,

    cntArrayType,
    cntOrdinalType,
    cntSubrangeType,
    cntSetType,
    cntFileType,
    cntOf,
    cntStringType,
    cntProcedureType,
    cntClassType,
    cntClassBody,
    cntClassHeritage,
    cntClassField,
    cntObjectType,
    cntInterfaceType,
    cntInterfaceHeritage,

    cntRecord,
    cntFieldList,
    cntFieldDecl,
    cntRecVariant,
    cntIdentList,

    cntConstSection,
    cntConstDecl,
    cntExportsSection,
    cntExportDecl,

    cntSetConstructor,
    cntSetElement,

    cntVisibility,
    cntProcedureHeading,
    cntFunctionHeading,
    cntProperty,
    cntPropertyInterface,
    cntPropertySpecifiers,
    cntPropertyParameterList,
    cntVarSection,
    cntVarDecl,
    cntTypedConstant,
    cntFormalParameters,
    cntFormalParam,

    cntProcedure,
    cntFunction,
    cntConstructor,
    cntDestructor,
    cntDirective,

    cntLabelId,
    cntSimpleStatement,

    cntExpressionList,
    cntConstExpression,
    cntConstExpressionInType,
    cntExpression,
    cntSimpleExpression,
    cntDesignator,
    cntQualId,
    cntTerm,
    cntFactor,

    cntEnd
  );

  TCnPasAstLeaf = class(TCnLeaf)
  {* Text 属性存对应的字符串}
  private
    FNodeType: TCnPasNodeType;
    FTokenKind: TTokenKind;
  public
    property NodeType: TCnPasNodeType read FNodeType write FNodeType;
    {* 语法树节点类型}
    property TokenKind: TTokenKind read FTokenKind write FTokenKind;
    {* Pascal Token 类型，注意有的节点本身没有实际对应的 Token，用 tkNone 代替}
  end;

  TCnPasAstTree = class(TCnTree)

  end;

  TCnPasAstGenerator = class
  private
    FLex: TCnGeneralPasLex;
    FTree: TCnPasAstTree;
    FStack: TCnObjectStack;
    FCurrentRef: TCnPasAstLeaf;
    FLocked: Integer;
    procedure Lock;
    procedure Unlock;
  protected
    procedure PushLeaf(ALeaf: TCnPasAstLeaf);
    procedure PopLeaf;

    procedure MatchCreateLeafAndPush(AToken: TTokenKind; NodeType: TCnPasNodeType = cntInvalid);
    // 将当前 Token 创建一个节点，作为 FCurrentRef 的最后一个子节点，再把 FCurrentRef 推入堆栈，自身取代 FCurrentRef
    function MatchCreateLeaf(AToken: TTokenKind; NodeType: TCnPasNodeType = cntInvalid): TCnPasAstLeaf;
    // 将当前 Token 创建一个节点，作为 FCurrentRef 的最后一个子节点
    procedure NextToken;
    // Lex 往前行进到下一个有效 Token，如果有注释，自行跳过（先不处理条件编译指令）
    function ForwardToken(Step: Integer = 1): TTokenKind;
    // 取下 Step 个有效 Token 但不往前行进，内部使用书签进行恢复
  public
    constructor Create(const Source: string); virtual;
    destructor Destroy; override;

    property Tree: TCnPasAstTree read FTree;
    {* Build 完毕后的语法树}

    // 有些语法部件是关键字开头，之后整一批子节点就行

    // 但有些比如二元运算，理论上是运算符要是父节点，元素是子节点，但是否真需要这样做？
    procedure Build;
    procedure BuildProgram;
    procedure BuildLibrary;
    procedure BuildUnit;

    procedure BuildProgramBlock;

    procedure BuildInterfaceSection;

    procedure BuildInterfaceDecl;

    procedure BuildImplementationSection;

    procedure BuildImplementationDecl;

    procedure BuildInitSection;

    procedure BuildDeclSection;

    procedure BuildExportedHeading;

    procedure BuildExportsSection;
    procedure BuildExportsList;
    procedure BuildExportsDecl;

    // Build 系列函数执行完后，FLex 均应 Next 到尾部之外的下一个 Token
    procedure BuildTypeSection;
    {* 碰上 type 关键字时被调用，新建 type 节点，其下是多个 typedecl 加分号，每个 typedecl 是新节点}
    procedure BuildTypeDecl;
    {* 被 BuildTypeSection 循环调用，每次新增一个节点并在下面增加 typedecl 内部各元素的子节点，不包括分号}
    procedure BulidRestrictedType;
    {* 受限类型}
    procedure BuildCommonType;
    {* 其他普通类型，对应 Type}

    procedure BuildSimpleType;
    {* 更简单的类型，Subrange/Enum/Ident，一定程度上能被 CommonType 覆盖}
    
    procedure BuildEnumeratedType;
    {* 组装一个枚举类型，(a, b) 这种}
    procedure BuildEnumeratedList;
    {* 组装一个枚举类型中的列表，(a, b) 这种中的 a, b}
    procedure BuildEmumeratedIdent;
    {* 组装一个枚举类型中的单项}

    procedure BuildStructType;
    procedure BuildArrayType;
    procedure BuildSetType;
    procedure BuildFileType;
    procedure BuildRecordType;
    procedure BuildProcedureType;
    procedure BuildPointerType;
    procedure BuildStringType;
    procedure BuildOrdinalType;
    procedure BuildSubrangeType;
    procedure BuildOrdIdentType;
    procedure BuildTypeID;
    procedure BuildGuid;

    procedure BuildClassType;
    procedure BuildClassBody;
    procedure BuildClassHeritage;
    procedure BuildClassMemberList;
    procedure BuildClassMembers;
    procedure BuildObjectType;
    procedure BuildInterfaceType;
    procedure BuildInterfaceHeritage;

    procedure BuildFieldList;
    procedure BuildClassVisibility;
    procedure BuildClassMethod;
    procedure BuildMethod;
    procedure BuildClassProperty;
    procedure BuildProperty;
    procedure BuildClassField;
    procedure BuildClassTypeSection;
    procedure BuildClassConstSection;
    procedure BuildVarSection;
    procedure BuildVarDecl;
    procedure BuildTypedConstant;
    procedure BuildRecVariant;
    procedure BuildFieldDecl;
    procedure BuildVariantSection;

    procedure BuildPropertyInterface;
    procedure BuildPropertyParameterList;
    procedure BuildPropertySpecifiers;

    procedure BuildFunctionHeading;
    procedure BuildProcedureHeading;
    procedure BuildConstructorHeading;
    procedure BuildDestructorHeading;

    procedure BuildFormalParameters;
    {* 组装函数过程的参数列表，包括两端的小括号}
    procedure BuildFormalParam;
    {* 组装函数过程的单个参数}

    procedure BuildConstSection;
    {* 组装常量声明块}
    procedure BuildConstDecl;
    {* 组装一个常量声明，不包括分号}

    procedure BuildDirectives;

    procedure BuildDirective;

    procedure BuildUsesClause;
    {* 碰上 uses 关键字时被调用，新建 uses 节点，其下是多个 usesdecl 加逗号，每个 uses 是新节点}
    procedure BuildUsesDecl;
    {* 被 BuildUsesClause 循环调用，每次新增一个节点并在下面增加 usesdecl 内部各元素的子节点}

    procedure BulidVarSection;
    
    procedure BuildSetConstructor;
    {* 组装一个集合表达式，有抽象节点}
    procedure BuildSetElement;
    {* 组装一个集合元素}

    procedure BuildCompoundStatement;

    procedure BuildStatementList;

    procedure BuildLabelId;
    {* 组装一个 LabelId}
    procedure BuildSimpleStatement;
    {* 组装一个简单语句，包括 Designator、Designator 及后面的赋值、inherited、Goto 等
      注意，语句开头如果是左小括号，无法直接判断是 Designator 类似于 (a)[0] := 1 这种、
            还是 SimpleStatement/Factor 类似于 (Caption := '') 这种}
    procedure BuildExpressionList;
    {* 组装一个表达式列表，由逗号分隔}
    procedure BuildExpression;
    {* 组装一个表达式，该表达式由 SimpleExpression 与二元运算符连接}
    procedure BuildConstExpression;
    {* 组装一常量表达式，类似于表达式}
    procedure BuildConstExpressionInType;
    {* 组装一类型声明中的常量表达式，类似于表达式，但不能出现等号等}
    procedure BuildSimpleExpression;
    {* 组装一个简单表达式，主要由 Term 组成，Term 之间用 AddOp 连接}
    procedure BuildTerm;
    {* 组装一个 Term，主要由 Factor 组成，Factor 之间用 MulOp 连接}
    procedure BuildFactor;
    {* 组装一个 Factor，虽然可以理解成语法树中除了简单标识符外的最简单部分，有抽象节点
      但其内部却有 Designator 这种单逻辑标识符，地位和简单标识符等同，@ 则另算}
    procedure BuildDesignator;
    {* 组装一个 Designator 标识符，主要是中括号的多维数组下标、以及小括号的 FunctionCall，以及指针的指^ 以及点 . 和后面的域标识符，不包括 @
      大概是指能够通过这几个运算符级联下去的单逻辑标识符，可以出现在 := 的左方，这和出现在 := 右方的 Expression 是不同的}
    procedure BuildQualId;
    {* 组装一个 QualId，主要是 Ident 以及 (Designator as Type)，作为 Designator 的起始部分}

    procedure BuildIdentList;
    procedure BuildIdent;
    {* 组装一个标识符，可以带点号}

  end;

function PascalAstNodeTypeToString(AType: TCnPasNodeType): string;

implementation

resourcestring
  SCnInvalidFileType = 'Invalid File Type!';
  SCnNotImplemented = 'NOT Implemented';
  SCnErrorStack = 'Stack Empty';
  SCnErrorNoMatchNodeType = 'No Matched Node Type';
  SCnErrorTokenNotMatchFmt = 'Token NOT Matched. Should %s, but meet %s: %s';

const
  SpaceTokens = [tkCRLF, tkCRLFCo, tkSpace];

  CommentTokens = [tkSlashesComment, tkAnsiComment, tkBorComment];

  RelOpTokens = [tkGreater, tkLower, tkGreaterEqual, tkLowerEqual, tkNotEqual,
    tkEqual, tkIn, tkAs, tkIs];

  AddOPTokens = [tkPlus, tkMinus, tkOr, tkXor];

  MulOpTokens = [tkStar, tkDiv, tkSlash, tkMod, tkAnd, tkShl, tkShr];

  VisibilityTokens = [tkPublic, tkPublished, tkProtected, tkPrivate];

  ProcedureTokens = [tkProcedure, tkFunction, tkConstructor, tkDestructor];

  PropertySpecifiersTokens = [tkDispid, tkRead, tkIndex, tkWrite, tkStored,
    tkImplements, tkDefault, tkNodefault, tkReadonly, tkWriteonly];

  ClassMethodTokens = [tkClass] + ProcedureTokens;

  ClassMemberTokens = [tkIdentifier, tkClass, tkProperty, tkType, tkConst]
     + ProcedureTokens;  // 不支持 class var/threadvar

  DirectiveTokens = [tkVirtual, tkOverride, tkAbstract, tkReintroduce, tkStdcall,
    tkCdecl, tkInline, tkName, tkIndex, tkLibrary, tkDefault, tkNoDefault,
    tkRead, tkReadonly, tkWrite, tkWriteonly, tkStored, tkImplements, tkOverload,
    tkPascal, tkRegister, tkExternal, tkAssembler, tkDynamic, tkAutomated,
    tkDispid, tkExport, tkFar, tkForward, tkNear, tkMessage, tkResident, tkSafecall];
    // 还有 platform, deprecated, unsafe, varargs 等一堆

  DirectiveTokensWithExpressions = [tkDispID, tkExternal, tkMessage, tkName,
    tkImplements, tkStored, tkRead, tkWrite, tkIndex];

  DeclSectionTokens = [tkClass, tkLabel, tkConst, tkResourcestring, tkType, tkVar,
    tkThreadvar, tkExports] + ProcedureTokens;

  InterfaceDeclTokens = [tkConst, tkResourcestring, tkThreadvar, tkType, tkVar,
    tkProcedure, tkFunction, tkExports];

function PascalAstNodeTypeToString(AType: TCnPasNodeType): string;
begin
  Result := GetEnumName(TypeInfo(TCnPasNodeType), Ord(AType));

  if Length(Result) > 3 then
  begin
    Delete(Result, 1, 3);
    Result := UpperCase(Result);
  end;
end;

function NodeTypeFromToken(AToken: TTokenKind): TCnPasNodeType;
begin
  case AToken of
    // Goal
    tkProgram: Result := cntProgram;
    tkLibrary: Result := cntLibrary;
    tkUnit: Result := cntUnit;

    // Section
    tkUses: Result := cntUsesClause;
    tkType: Result := cntTypeSection;
    tkExports: Result := cntExportsSection;
    tkVar, tkThreadvar: Result := cntVarSection;
    // tkConst: Result := cntConstSection;

    // 语句块
    tkEnd: Result := cntEnd;
    tkProcedure: Result := cntProcedure;
    tkFunction: Result := cntFunction;
    tkConstructor: Result := cntConstructor;
    tkDestructor: Result := cntDestructor;

        

    // 元素：注释
    tkBorComment, tkAnsiComment: Result := cntBlockComment;
    tkSlashesComment: Result := cntLineComment;

    // 元素：标识符和数字、字符串等
    tkIdentifier: Result := cntIdent;
    tkInteger, tkNumber: Result := cntInt; // 十六进制整数和普通整数
    tkFloat: Result := cntFloat;
    tkAsciiChar, tkString: Result := cntString;

    // 元素：符号与运算符等
    tkComma: Result := cntComma;
    tkSemiColon: Result := cntSemiColon;
    tkColon: Result := cntColon;
    tkDotDot: Result := cntRange;
    tkPoint: Result := cntDot;
    tkPointerSymbol: Result := cntHat;
    tkAssign: Result := cntAssign;

    tkPlus, tkMinus, tkOr, tkXor: Result := cntAddOps;
    tkStar, tkDiv, tkSlash, tkMod, tkAnd, tkShl, tkShr: Result := cntMulOps;
    tkGreater, tkLower, tkGreaterEqual, tkLowerEqual, tkNotEqual, tkEqual, tkIn, tkAs, tkIs:
      Result := cntRelOps;

    tkSquareOpen: Result := cntSquareOpen;
    tkSquareClose: Result := cntSquareClose;
    tkRoundOpen: Result := cntRoundOpen;
    tkRoundClose: Result := cntRoundClose;

    // 类型
    tkArray: Result := cntArrayType;
    tkSet: Result := cntSetType;
    tkFile: Result := cntFileType;
    tkOf: Result := cntOf;
    tkRecord, tkPacked: Result := cntRecord;
    tkInterface, tkDispinterface: Result := cntInterfaceType; // interface section 由外界指定
    tkClass: Result := cntClassType;

    // 属性
    tkProperty: Result := cntProperty;
    tkConst, tkResourcestring: Result := cntConstSection;
    tkIndex: Result := cntIndex;  // TODO: 属性的 Index 要与 Directives 的 index 区分
    tkRead: Result := cntRead;
    tkWrite: Result := cntWrite;
    tkImplements: Result := cntImplements;
    tkDefault: Result := cntDefault;
    tkStored: Result := cntStored;
    tkNodefault: Result := cntNodefault;
    tkReadonly: Result := cntReadonly;
    tkWriteonly: Result := cntWriteonly;

    tkPrivate, tkProtected, tkPublic, tkPublished: Result := cntVisibility;
    tkVirtual, tkOverride, tkAbstract, tkReintroduce, tkStdcall, tkCdecl, tkInline, tkName:
      Result := cntDirective;
  else
    raise ECnPascalAstException.Create(SCnErrorNoMatchNodeType + ' '
      + GetEnumName(TypeInfo(TTokenKind), Ord(AToken)));
  end;
end;

{ TCnPasASTGenerator }

procedure TCnPasAstGenerator.Build;
begin
  case FLex.TokenID of
    tkProgram:
      BuildProgram;
    tkLibrary:
      BuildLibrary;
    tkUnit:
      BuildUnit;
  else
    raise ECnPascalAstException.Create(SCnInvalidFileType);
  end;
end;

procedure TCnPasAstGenerator.BuildArrayType;
begin
  MatchCreateLeafAndPush(tkArray);

  try
    if FLex.TokenID = tkSquareOpen then
    begin
      MatchCreateLeafAndPush(tkSquareOpen);
      try
        repeat
          BuildOrdinalType;
          if FLex.TokenID = tkComma then
            MatchCreateLeaf(tkComma)
          else
            Break;
        until False;
      finally
        PopLeaf;
      end;
      MatchCreateLeaf(tkSquareClose);
    end;

    MatchCreateLeaf(tkOf);
    BuildCommonType; // Array 后的类型只能是 Common Type，不支持 class 等
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassType;
begin
  MatchCreateLeafAndPush(FLex.TokenID);

  try
    if FLex.TokenID = tkSemiColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      Exit;
    end;

    if FLex.TokenID = tkOf then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildIdent;
      Exit;
    end;

    if FLex.TokenID in [tkAbstract, tkSealed] then
      MatchCreateLeaf(FLex.TokenID);

    BuildClassBody; // 分号在 TypeDecl 中处理
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildConstExpression;
begin
  // 和 BuildExpression 相同只是节点类型不同
  MatchCreateLeafAndPush(tkNone, cntConstExpression);
  // Pop 之前，内部添加的节点均为抽象的 ConstExpression 节点之子

  try
    BuildSimpleExpression;
    while FLex.TokenID in RelOpTokens + [tkPoint, tkPointerSymbol, tkSquareOpen] do
    begin
      if FLex.TokenID in RelOpTokens then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildSimpleExpression;
      end
      else if FLex.TokenID = tkPointerSymbol then // 注意，这 . ^ [] 是扩展而来，原始语法里没有
        MatchCreateLeaf(FLex.TokenID)
      else if FLex.TokenID = tkPoint then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildIdent;
      end
      else if FLex.TokenID = tkSquareOpen then
      begin
        MatchCreateLeafAndPush(FLex.TokenID);
        try
          BuildExpressionList;
        finally
          PopLeaf;
        end;
        MatchCreateLeaf(tkSquareClose);
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildDesignator;
begin
  MatchCreateLeafAndPush(tkNone, cntDesignator);
  // Pop 之前，内部添加的节点均为抽象的 Expression 节点之子

  try
    BuildQualId;
    while FLex.TokenID in [tkSquareOpen, tkRoundOpen, tkPoint, tkPointerSymbol] do
    begin
      case FLex.TokenID of
        tkSquareOpen: // 数组下标
          begin
            MatchCreateLeafAndPush(tkSquareOpen);
            // Pop 之前，内部添加的节点均为左中括号节点之子

            try
              BuildExpressionList;
            finally
              PopLeaf;
            end;
            MatchCreateLeaf(tkSquareClose); // 子节点整完后回退一层，再放上配套的右中括号
          end;
        tkRoundOpen: // Function Call
          begin
            MatchCreateLeafAndPush(tkRoundOpen);
            // Pop 之前，内部添加的节点均为左中括号节点之子

            try
              BuildExpressionList;
            finally
              PopLeaf;
            end;
            MatchCreateLeaf(tkRoundClose); // 子节点整完后回退一层，再放上配套的右中括号
          end;
        tkPointerSymbol:
          begin
            MatchCreateLeaf(FLex.TokenID);
          end;
        tkPoint:
          begin
            MatchCreateLeaf(FLex.TokenID);
            BuildIdent;
          end;
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildEmumeratedIdent;
begin
  MatchCreateLeafAndPush(tkNone, cntEmumeratedIdent);

  try
    BuildIdent;
    if FLex.TokenID = tkEqual then
    begin
      MatchCreateLeaf(tkEqual);
      BuildConstExpression;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildEnumeratedList;
begin
  MatchCreateLeafAndPush(tkNone, cntEnumeratedList);

  try
    repeat
      BuildEmumeratedIdent;
      if FLex.TokenID = tkComma then
        MatchCreateLeaf(tkComma)
      else
        Break;
    until False;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildEnumeratedType;
begin
  MatchCreateLeafAndPush(tkRoundOpen);

  try
    BuildEnumeratedList;
  finally
    PopLeaf;
  end;
  MatchCreateLeaf(tkRoundClose);
end;

procedure TCnPasAstGenerator.BuildExpression;
begin
  MatchCreateLeafAndPush(tkNone, cntExpression);
  // Pop 之前，内部添加的节点均为抽象的 Expression 节点之子

  try
    BuildSimpleExpression;
    while FLex.TokenID in RelOpTokens + [tkPoint, tkPointerSymbol, tkSquareOpen] do
    begin
      if FLex.TokenID in RelOpTokens then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildSimpleExpression;
      end
      else if FLex.TokenID = tkPointerSymbol then // 注意，这 . ^ [] 是扩展而来，原始语法里没有
        MatchCreateLeaf(FLex.TokenID)
      else if FLex.TokenID = tkPoint then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildIdent;
      end
      else if FLex.TokenID = tkSquareOpen then
      begin
        MatchCreateLeafAndPush(FLex.TokenID);
        try
          BuildExpressionList;
        finally
          PopLeaf;
        end;
        MatchCreateLeaf(tkSquareClose);
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildExpressionList;
begin
  MatchCreateLeafAndPush(tkNone, cntExpressionList);
  // Pop 之前，内部添加的节点均为抽象的 ExpressionList 节点之子

  try
    repeat
      BuildExpression;
      if FLex.TokenID = tkComma then
        MatchCreateLeaf(tkComma)
      else
        Break;
    until False;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFactor;
begin
  MatchCreateLeafAndPush(tkNone, cntFactor);
  // Pop 之前，内部添加的节点均为抽象的 Factor 节点之子

  try
    case FLex.TokenID of
      tkAt:
        begin
          MatchCreateLeafAndPush(FLex.TokenID);
          // Pop 之前，内部添加的节点均为 @ 节点之子

          try
            BuildDesignator;
          finally
            PopLeaf;
          end;
        end;
      tkIdentifier:
        begin
          BuildDesignator;
          if FLex.TokenID = tkRoundOpen then
          begin
            MatchCreateLeaf(tkRoundOpen);
            BuildExpressionList;
            MatchCreateLeaf(tkRoundClose)
          end;
        end;
      tkAsciiChar, tkString, tkNumber, tkInteger, tkFloat: // AsciiChar 是 #12 这种
        MatchCreateLeaf(FLex.TokenID);
      tkNot:
        begin
          MatchCreateLeaf(FLex.TokenID);
          BuildFactor;
        end;
      tkSquareOpen:
        begin
          BuildSetConstructor;
        end;
      tkInherited:
        begin
          MatchCreateLeafAndPush(FLex.TokenID);
          // Pop 之前，内部添加的节点均为 inherited 节点之子

          try
            BuildExpression;
          finally
            PopLeaf;
          end;
        end;
      tkRoundOpen:
        begin
          MatchCreateLeafAndPush(FLex.TokenID);
          // Pop 之前，内部添加的节点均为左小括号节点之子

          try
            BuildExpression;
          finally
            PopLeaf;
          end;
          MatchCreateLeaf(tkRoundClose); // 子节点整完后回退一层，再放上配套的右小括号

          while FLex.TokenID = tkPointerSymbol do
            MatchCreateLeaf(tkPointerSymbol)
        end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFileType;
begin
  MatchCreateLeafAndPush(tkFile);

  try
    if FLex.TokenID = tkOf then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildTypeID;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildIdent;
var
  T: TCnPasAstLeaf;
begin
  T := MatchCreateLeaf(tkIdentifier);

  while FLex.TokenID in [tkPoint, tkIdentifier] do
  begin
    if T <> nil then
      T.Text := T.Text + FLex.Token;
    NextToken;
  end;
end;

procedure TCnPasAstGenerator.BuildLabelId;
begin
  MatchCreateLeaf(tkIdentifier);
end;

procedure TCnPasAstGenerator.BuildOrdinalType;
var
  Bookmark: TCnGeneralLexBookmark;
  IsRange: Boolean;

  procedure SkipOrdinalPrefix;
  begin
    repeat
      FLex.NextNoJunk;
    until not (FLex.TokenID in [tkIdentifier, tkPoint, tkInteger, tkString, tkRoundOpen, tkSquareOpen,
      tkPlus, tkMinus, tkStar, tkSlash, tkDiv, tkMod]);
  end;

begin
  MatchCreateLeafAndPush(tkNone, cntOrdinalType);

  try
    if FLex.TokenID = tkRoundOpen then  // (a, b) 这种
      BuildEnumeratedType
    else
    begin
      Lock;
      FLex.SaveToBookmark(Bookmark);

      try
        SkipOrdinalPrefix;
        IsRange := FLex.TokenID = tkDotDot;
      finally
        FLex.LoadFromBookmark(Bookmark);
        Unlock;
      end;

      if IsRange then
        BuildSubrangeType
      else
        BuildOrdIdentType;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildProcedureType;
begin
  MatchCreateLeafAndPush(tkNone, cntProcedureType);

  try
    if FLex.TokenID = tkProcedure then
    begin
      BuildProcedureHeading;
    end
    else if FLex.TokenID = tkFunction then
    begin
      BuildFunctionHeading;
    end;
    if FLex.TokenID = tkOf then
    begin
      MatchCreateLeaf(tkOf);
      MatchCreateLeaf(tkObject);
    end;

    // TODO: Directives
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildQualId;
begin
  MatchCreateLeafAndPush(tkNone, cntQualId);
  // Pop 之前，内部添加的节点均为抽象的 QualId 节点之子

  try
    case FLex.TokenID of
      tkIdentifier:
        BuildIdent;
      tkRoundOpen:
        begin
          MatchCreateLeafAndPush(FLex.TokenID);
          // Pop 之前，内部添加的节点均为左小括号节点之子

          try
            BuildDesignator;
            if FLex.TokenID = tkAs then
            begin
              MatchCreateLeaf(tkAs);
              BuildIdent; // TypeId 沿用 Ident
            end;
          finally
            PopLeaf;
          end;
          MatchCreateLeaf(tkRoundClose); // 子节点整完后回退一层，再放上配套的右小括号
        end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildRecordType;
begin
  MatchCreateLeafAndPush(tkRecord);

  try
    if FLex.TokenID <> tkEnd then
      BuildFieldList;
    MatchCreateLeaf(tkEnd);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSetConstructor;
begin
  MatchCreateLeafAndPush(tkNone, cntSetConstructor);
  // Pop 之前，内部添加的节点均为抽象的 SetConstructor 节点之子

  try
    MatchCreateLeafAndPush(tkSquareOpen);
   // Pop 之前，内部添加的节点均为左中括号节点之子

    try
      while True do
      begin
        BuildSetElement;
        if FLex.TokenID = tkComma then
          MatchCreateLeaf(tkComma)
        else
          Break;
      end;
    finally
      PopLeaf;
    end;
    MatchCreateLeaf(tkSquareClose); // 子节点整完后回退一层，再放上配套的右中括号
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSetElement;
begin
  MatchCreateLeafAndPush(tkNone, cntSetElement);
  // Pop 之前，内部添加的节点均为抽象的 SetElement 节点之子

  try
    BuildExpression;
    if FLex.TokenID = tkDotDot then
    begin
      MatchCreateLeaf(tkDotDot);
      BuildExpression;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSetType;
begin
  MatchCreateLeafAndPush(tkNone, cntSetType);
  // Pop 之前，内部添加的节点均为抽象的 SetType 节点之子

  try
    MatchCreateLeaf(tkSet);
    MatchCreateLeaf(tkOf);
    BuildOrdinalType;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSimpleExpression;
begin
  MatchCreateLeafAndPush(tkNone, cntSimpleExpression);
  // Pop 之前，内部添加的节点均为抽象的 SimpleExpression 节点之子

  try
    if FLex.TokenID in [tkPlus, tkMinus, tkPointerSymbol] then
      MatchCreateLeaf(FLex.TokenID);

    BuildTerm;
    if FLex.TokenID in AddOpTokens then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildTerm;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSimpleStatement;
var
  Bookmark: TCnGeneralLexBookmark;
  IsDesignator: Boolean;
begin
  MatchCreateLeafAndPush(tkNone, cntSimpleStatement);
  // Pop 之前，内部添加的节点均为抽象的 SimpleStatement 节点之子

  try
    if FLex.TokenID = tkGoto then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildLabelId;
    end
    else if FLex.TokenID = tkInherited then
    begin
      MatchCreateLeaf(FLex.TokenID);
      // 后面可能没了，也可能是另一个 SimpleStatement
      if not (FLex.TokenID in [tkSemicolon, tkEnd, tkElse]) then
        BuildSimpleStatement;
    end
    else if FLex.TokenID = tkRoundOpen then
    begin
      // ( Statement ) 这种，但不易与 Designator 区分开来，需要另想办法区分
      FLex.SaveToBookmark(Bookmark);
      Lock;
      try
        // 向前判断是否 Designator
        try
          BuildDesignator;
          // 假设 Designator 处理完毕，判断后续是啥

          IsDesignator := FLex.TokenID in [tkAssign, tkRoundOpen, tkSemicolon,
            tkElse, tkEnd];
          // TODO: 目前只想到这几个。Semicolon 是怕 Designator 已经作为语句处理完了，
          // else/end 是怕语句结束没分号导致判断失误。
        except
          IsDesignator := False;
          // 如果后面碰到了 := 等情形，BuildDesignator 会出错，
          // 说明本句是带括号嵌套的 Simplestatement
        end;
      finally
        Unlock;
        FLex.LoadFromBookmark(Bookmark);
      end;

      if IsDesignator then // 是 Designator，处理后面可能有的赋值
      begin
        BuildDesignator;
        if FLex.TokenID = tkAssign then
        begin
          MatchCreateLeaf(FLex.TokenID);
          BuildExpression;
        end;
      end
      else // 是 ( Statement )
      begin
        MatchCreateLeafAndPush(tkRoundOpen);
        // Pop 之前，内部添加的节点均为左小括号节点之子

        try
          BuildSimpleStatement; // TODO: 改为 Statement
        finally
          PopLeaf;
        end;
        MatchCreateLeaf(tkRoundClose);
      end;
    end
    else // 非 ( 开头，也是 Designator，处理后面可能有的赋值
    begin
      BuildDesignator;
      if FLex.TokenID = tkAssign then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildExpression;
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildStringType;
begin
  MatchCreateLeafAndPush(tkNone, cntStringType);

  try
    if FLex.TokenID = tkString then
      MatchCreateLeaf(FLex.TokenID)
    else
      BuildIdent;

    if FLex.TokenID = tkRoundOpen then
    begin
      MatchCreateLeafAndPush(FLex.TokenID);
      try
        BuildExpression;
      finally
        PopLeaf;
      end;
      MatchCreateLeaf(tkRoundClose);
    end
    else if FLex.TokenID = tkSquareOpen then
    begin
      MatchCreateLeafAndPush(FLex.TokenID);
      try
        BuildConstExpression;
      finally
        PopLeaf;
      end;
      MatchCreateLeaf(tkSquareClose);
    end
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildStructType;
begin
  if FLex.TokenID = tkPacked then
    MatchCreateLeaf(tkPacked);

  case FLex.TokenID of
    tkArray:
      BuildArrayType;
    tkSet:
      BuildSetType;
    tkFile:
      BuildFileType;
    tkRecord:
      BuildRecordType;
  end;
end;

procedure TCnPasAstGenerator.BuildTerm;
begin
  MatchCreateLeafAndPush(tkNone, cntTerm);
  // Pop 之前，内部添加的节点均为抽象的 Term 节点之子

  try
    BuildFactor;
    if FLex.TokenID in MulOpTokens then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildFactor;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildCommonType;
var
  Bookmark: TCnGeneralLexBookmark;
  IsRange: Boolean;
begin
  MatchCreateLeafAndPush(tkNone, cntCommonType);

  try
    case FLex.TokenID of
      tkRoundOpen:
        begin
          BuildEnumeratedType;
        end;
      tkPacked, tkArray, tkSet, tkFile, tkRecord:
        begin
          BuildStructType;
        end;
      tkProcedure, tkFunction:
        begin
          BuildProcedureType;
        end;
      tkPointerSymbol:
        begin
          BuildPointerType;
        end;
    else
      if (FLex.TokenID = tkString) or SameText(FLex.Token, 'String')
        or SameText(FLex.Token, 'AnsiString') or SameText(FLex.Token, 'WideString')
        or SameText(FLex.Token, 'UnicodeString') then
        BuildStringType
      else
      begin
        // TypeID? 越过一个 ConstExpressionInType 后看是否是 ..
        Lock;
        FLex.SaveToBookmark(Bookmark);

        try
          BuildConstExpressionInType;
          IsRange := FLex.TokenID = tkDotDot;
        finally
          FLex.LoadFromBookmark(Bookmark);
          UnLock;
        end;

        if IsRange then
          BuildSubrangeType
        else
          BuildTypeID;
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildTypeDecl;
begin
  MatchCreateLeafAndPush(tkNone, cntTypeDecl);
  // Pop 之前，内部添加的节点均为 TypeDecl 节点之子

  try
    BuildIdent;
    MatchCreateLeaf(tkEqual);
    if FLex.TokenID = tkType then
      MatchCreateLeaf(tkNone, cntTypeKeyword);

    // 要分开 RestrictType 和普通 Type，前者包括 class/object/interface，部分场合不允许出现
    if FLex.TokenID in [tkClass, tkObject, tkInterface, tkDispInterface] then
      BulidRestrictedType
    else
      BuildCommonType;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildTypeSection;
begin
  MatchCreateLeafAndPush(tkType);
  // Pop 之前，内部添加的节点均为 type 节点之子

  try
    while FLex.TokenID = tkIdentifier do
    begin
      BuildTypeDecl;
      MatchCreateLeaf(tkSemiColon);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildUsesClause;
begin
  if FLex.TokenID in [tkUses, tkRequires, tkContains] then
    MatchCreateLeafAndPush(FLex.TokenID);

  // Pop 之前，内部添加的节点均为 Uses 节点之子

  try
    while True do
    begin
      BuildUsesDecl;
      if FLex.TokenID = tkComma then
        MatchCreateLeaf(tkComma)
      else
        Break;
    end;

    MatchCreateLeaf(tkSemiColon);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildUsesDecl;
begin
  BuildIdent;
  if FLex.TokenID = tkIn then
  begin
    MatchCreateLeaf(tkIn);
    MatchCreateLeaf(tkString);
  end;
end;

procedure TCnPasAstGenerator.BulidRestrictedType;
begin
  MatchCreateLeafAndPush(tkNone, cntRestrictedType);

  try
    case FLex.TokenID of
      tkClass:
        BuildClassType;
      tkObject:
        BuildObjectType;
      tkInterface, tkDispinterface:
        BuildInterfaceType;
    end;
  finally
    PopLeaf;
  end;
end;

constructor TCnPasASTGenerator.Create(const Source: string);
begin
  inherited Create;
  FLex := TCnGeneralPasLex.Create;
  FStack := TCnObjectStack.Create;
  FTree := TCnPasAstTree.Create(TCnPasAstLeaf);
  FCurrentRef := FTree.Root as TCnPasAstLeaf;

  FLex.Origin := PChar(Source);
end;

destructor TCnPasASTGenerator.Destroy;
begin
  FTree.Free;
  FStack.Free;
  FLex.Free;
  inherited;
end;

procedure TCnPasAstGenerator.Lock;
begin
  Inc(FLocked);
end;

function TCnPasAstGenerator.MatchCreateLeaf(AToken: TTokenKind;
  NodeType: TCnPasNodeType): TCnPasAstLeaf;
begin
  Result := nil;
  if (AToken <> tkNone) and (AToken <> FLex.TokenID) then
    raise ECnPascalAstException.CreateFmt(SCnErrorTokenNotMatchFmt,
      [GetEnumName(TypeInfo(TTokenKind), Ord(AToken)),
       GetEnumName(TypeInfo(TTokenKind), Ord(FLex.TokenID)),
       FLex.Token]);

  if NodeType = cntInvalid then
    NodeType := NodeTypeFromToken(AToken);

  if FLocked = 0 then // 未锁才创建节点
  begin
    if (FCurrentRef <> nil) and (FTree.Root <> FCurrentRef) then
      Result := FTree.AddChild(FCurrentRef) as TCnPasAstLeaf
    else
      Result := FTree.AddChild(FTree.Root) as TCnPasAstLeaf;

    Result.TokenKind := AToken;
    Result.NodeType := NodeType;
  end;

  if AToken <> tkNone then // 有内容的实际节点，才步进一下
  begin
    if FLocked = 0 then               // 未锁才处理
      Result.Text := FLex.Token;
    NextToken;                        // 锁不锁都要前进
  end;
end;

procedure TCnPasAstGenerator.MatchCreateLeafAndPush(AToken: TTokenKind;
  NodeType: TCnPasNodeType);
var
  T: TCnPasAstLeaf;
begin
  T := MatchCreateLeaf(AToken, NodeType);
  if T <> nil then
  begin
    PushLeaf(FCurrentRef);
    FCurrentRef := T;  // Pop 之前，内部添加的节点均为该节点之子
  end;
end;

procedure TCnPasAstGenerator.NextToken;
begin
  repeat
    FLex.Next;
  until not (FLex.TokenID in SpaceTokens + CommentTokens);
end;

function TCnPasAstGenerator.ForwardToken(Step: Integer): TTokenKind;
var
  Cnt: Integer;
  Bookmark: TCnGeneralLexBookmark;
begin
  FLex.SaveToBookmark(Bookmark);

  Cnt := 0;
  try
    while True do
    begin
      NextToken;
      Inc(Cnt);
      Result := FLex.TokenID;

      if Cnt >= Step then
        Exit;
    end;
  finally
    FLex.LoadFromBookmark(Bookmark);
  end;
end;

procedure TCnPasAstGenerator.PopLeaf;
begin
  if FLocked > 0 then // 锁着时不 Pop，因为 Push 也锁了
    Exit;

  if FStack.Count <= 0 then
    raise ECnPascalAstException.Create(SCnErrorStack);

  FCurrentRef := TCnPasAstLeaf(FStack.Pop);
end;

procedure TCnPasAstGenerator.PushLeaf(ALeaf: TCnPasAstLeaf);
begin
  if ALeaf <> nil then
    FStack.Push(ALeaf);
end;

procedure TCnPasAstGenerator.Unlock;
begin
  Dec(FLocked);
end;

procedure TCnPasAstGenerator.BuildInterfaceType;
begin
  MatchCreateLeafAndPush(FLex.TokenID);

  try
    if FLex.TokenID = tkSemiColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      Exit;
    end;

    if FLex.TokenID = tkRoundOpen then
      BuildInterfaceHeritage;

    if FLex.TokenID = tkSquareOpen then
      BuildGuid;

    while FLex.TokenID in VisibilityTokens + ProcedureTokens + [tkProperty] do
    begin
      if FLex.TokenID in VisibilityTokens then
        BuildClassVisibility
      else if FLex.TokenID in ProcedureTokens then
        BuildMethod  // 注意不是 ClassMethod，因为接口不支持 class function 这种
      else if Flex.TokenID = tkProperty then
        BuildProperty;

    end;
    MatchCreateLeaf(tkEnd);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildObjectType;
begin
  raise ECnPascalAstException.Create(SCnNotImplemented);
end;

procedure TCnPasAstGenerator.BuildOrdIdentType;
begin
  BuildIdent;
end;

procedure TCnPasAstGenerator.BuildSubrangeType;
begin
  MatchCreateLeafAndPush(tkNone, cntSubrangeType);

  try
    BuildConstExpression;
    MatchCreateLeaf(tkDotDot);
    BuildConstExpression;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildPointerType;
begin
  MatchCreateLeafAndPush(tkPointerSymbol, cntHat);

  try
    BuildTypeID;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildTypeID;
begin
  MatchCreateLeafAndPush(tkNone, cntTypeID);

  try
    if FLex.TokenID = tkString then // 和 BuildIdent 内部不认关键字
      MatchCreateLeaf(FLex.TokenID)
    else
      BuildIdent;
    if FLex.TokenID = tkRoundOpen then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildExpression;
      MatchCreateLeaf(tkRoundClose)
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFieldList;
begin
  MatchCreateLeafAndPush(tkNone, cntFieldList);

  try
    while not (FLex.TokenID in [tkEnd, tkCase, tkRoundClose]) do
    begin
      if FLex.TokenID in VisibilityTokens then
        BuildClassVisibility;

      if FLex.TokenID = tkCase then
        Break
      else if FLex.TokenID in ProcedureTokens then
        BuildMethod
      else if FLex.TokenID = tkProperty then
        BuildProperty
      else if FLex.TokenID = tkType then
        BuildClassTypeSection
      else if FLex.TokenID = tkConst then
        BuildClassConstSection
      else if FLex.TokenID in [tkVar, tkThreadVar] then
        BuildVarSection
      else if FLex.TokenID <> tkEnd then
      begin
        BuildFieldDecl;
        if FLex.TokenID = tkSemiColon then
          MatchCreateLeaf(tkSemiColon);
      end;
    end;

    // 处理 case 可变体
    if FLex.TokenID = tkCase then
      BuildVariantSection;

    if FLex.TokenID = tkSemiColon then
      MatchCreateLeaf(tkSemiColon);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildIdentList;
begin
  MatchCreateLeafAndPush(tkNone, cntIdentList);

  try
    repeat
      BuildIdent;
      if FLex.TokenID = tkComma then
        MatchCreateLeaf(tkComma)
      else
        Break;
    until False;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFunctionHeading;
begin
  MatchCreateLeafAndPush(tkFunction);

  try
    BuildIdent;
    if FLex.TokenID = tkRoundOpen then
      BuildFormalParameters;

    MatchCreateLeaf(tkColon);
    BuildCommonType;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildProcedureHeading;
begin
  MatchCreateLeafAndPush(tkProcedure);

  try
    BuildIdent;
    if FLex.TokenID = tkRoundOpen then
      BuildFormalParameters;

    if FLex.TokenID = tkEqual then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildIdent;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassConstSection;
begin

end;

procedure TCnPasAstGenerator.BuildMethod;
begin
  case FLex.TokenID of
    tkProcedure:
      BuildProcedureHeading;
    tkFunction:
      BuildFunctionHeading;
    tkConstructor:
      BuildConstructorHeading;
    tkDestructor:
      BuildDestructorHeading;
  end;
  MatchCreateLeaf(tkSemiColon);

  BuildDirectives;
end;

procedure TCnPasAstGenerator.BuildClassTypeSection;
begin
  MatchCreateLeafAndPush(tkType);

  try
    while FLex.TokenID = tkIdentifier do
    begin
      BuildTypeDecl; // 类似于 BuildTypeSection，复用之
      MatchCreateLeaf(tkSemiColon);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassVisibility;
begin
  MatchCreateLeaf(FLex.TokenID);
end;

procedure TCnPasAstGenerator.BuildVariantSection;
var
  Bookmark: TCnGeneralLexBookmark;
  HasColon: Boolean;
begin
  MatchCreateLeafAndPush(tkCase, cntVariantSection);

  try
    Lock;
    FLex.SaveToBookmark(Bookmark);

    try
      BuildIdent;
      HasColon := FLex.TokenID = tkColon;
    finally
      FLex.LoadFromBookmark(Bookmark);
      Unlock;
    end;

    if HasColon then
    begin
      BuildIdent;
      MatchCreateLeaf(tkColon);
      BuildTypeID;
    end
    else
      BuildTypeID;

    MatchCreateLeaf(tkOf);
    repeat
      BuildRecVariant;
      if FLex.TokenID = tkSemiColon then
      begin
        MatchCreateLeaf(FLex.TokenID);
        if FLex.TokenID in [tkEnd, tkRoundClose] then
          Break;
      end
      else
        Break;
    until False;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildVarSection;
begin
  MatchCreateLeafAndPush(tkVar);

  try
    while FLex.TokenID in [tkIdentifier] do
    begin
      BuildVarDecl;
      MatchCreateLeaf(tkSemiColon);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFieldDecl;
begin
  MatchCreateLeafAndPush(tkNone, cntFieldDecl);

  try
    BuildIdentList;
    MatchCreateLeaf(tkColon);
    BuildCommonType;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildProperty;
begin
  MatchCreateLeafAndPush(tkProperty);

  try
    BuildIdent;
    if FLex.TokenID in [tkSquareOpen, tkColon] then
      BuildPropertyInterface;
    BuildPropertySpecifiers;
    MatchCreateLeaf(tkSemiColon);

    if FLex.TokenID = tkDefault then
    begin
      MatchCreateLeaf(FLex.TokenID);
      MatchCreateLeaf(tkSemiColon);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildRecVariant;
begin
  MatchCreateLeafAndPush(tkNone, cntRecVariant);

  try
    repeat
      BuildConstExpression;
      if FLex.TokenID = tkComma then
        MatchCreateLeaf(tkComma)
      else
        Break;
    until False;

    MatchCreateLeaf(tkColon);
    if FLex.TokenID = tkRoundOpen then
    begin
      MatchCreateLeafAndPush(tkRoundOpen);

      try
        BuildFieldList;
      finally
        PopLeaf;
      end;
      MatchCreateLeaf(tkRoundClose);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildPropertyInterface;
begin
  MatchCreateLeafAndPush(tkNone, cntPropertyInterface);

  try
    if FLex.TokenID <> tkColon then
      BuildPropertyParameterList;
    MatchCreateLeaf(tkColon);
    BuildCommonType;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildPropertySpecifiers;
var
  ID: TTokenKind;
begin
  MatchCreateLeafAndPush(tkNone, cntPropertySpecifiers);

  try
    while FLex.TokenID in PropertySpecifiersTokens do
    begin
      ID := FLex.TokenID;
      MatchCreateLeaf(FLex.TokenID);
      case ID of
        tkDispid:
          begin
            BuildExpression;
          end;
        tkIndex, tkStored, tkDefault:
          begin
            BuildConstExpression;
          end;
        tkRead, tkWrite:
          begin
            BuildDesignator;
          end;
        tkImplements:
          begin
            BuildTypeID;
          end;
        // tkNodefault, tkReadonly, tkWriteonly 直接 Match 掉
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildPropertyParameterList;
begin
  MatchCreateLeafAndPush(tkNone, cntPropertyParameterList);

  try
    MatchCreateLeafAndPush(tkSquareOpen);

    repeat
      if FLex.TokenID in [tkVar, tkConst, tkOut] then
        MatchCreateLeaf(FLex.TokenID); // TODO: 区分 var/const 修饰的内容与 VarSection、ConstSection

      BuildIdentList;
      MatchCreateLeaf(tkColon);
      BuildTypeID;

      if FLex.TokenID <> tkSemiColon then
        Break;
    until False;

    MatchCreateLeaf(tkSquareClose);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildVarDecl;
begin
  MatchCreateLeafAndPush(tkNone, cntVarDecl);

  try
    BuildIdentList;
    if FLex.TokenID = tkColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildCommonType;
    end;

    if FLex.TokenID = tkEqual then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildTypedConstant;
    end
    else if FLex.TokenID = tkAbsolute then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildConstExpression; // 包括 Ident 的情形
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildTypedConstant;
type
  TCnTypedConstantType = (tcConst, tcArray, tcRecord);
var
  TypedConstantType: TCnTypedConstantType;
begin
  MatchCreateLeafAndPush(tkNone, cntTypedConstant);

  try
    if FLex.TokenID = tkSquareOpen then
    begin
      BuildSetConstructor;
      while FLex.TokenID in (AddOPTokens + MulOPTokens) do
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildSetConstructor;
      end;
    end
    else if FLex.TokenID = tkRoundOpen then
    begin
      // TODO: 判断是数组常量还是结构常量
      if ForwardToken = tkRoundOpen then
      begin

      end
      else
      begin

      end;
    end
    else
      BuildConstExpression;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildInterfaceHeritage;
begin
  MatchCreateLeafAndPush(tkNone, cntInterfaceHeritage);

  try
    MatchCreateLeafAndPush(tkRoundOpen);
    try
      BuildIdentList;
    finally
      PopLeaf;
    end;
    MatchCreateLeaf(tkRoundClose);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildGuid;
begin
  MatchCreateLeafAndPush(tkNone, cntGuid);

  try
    MatchCreateLeafAndPush(tkSquareOpen);
    try
      MatchCreateLeaf(tkString); // 内容是一个字符串
    finally
      PopLeaf;
    end;
    MatchCreateLeaf(tkSquareClose);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassMethod;
begin
  if FLex.TokenID = tkClass then
    MatchCreateLeaf(FLex.TokenID);
  BuildMethod;
end;

procedure TCnPasAstGenerator.BuildClassProperty;
begin
  if FLex.TokenID = tkClass then
    MatchCreateLeaf(FLex.TokenID);
  BuildProperty;
end;

procedure TCnPasAstGenerator.BuildConstructorHeading;
begin
  MatchCreateLeafAndPush(tkConstructor);

  try
    BuildIdent;
    if FLex.TokenID = tkRoundOpen then
      BuildFormalParameters;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildDestructorHeading;
begin
  MatchCreateLeafAndPush(tkDestructor);

  try
    BuildIdent;
    if FLex.TokenID = tkRoundOpen then
      BuildFormalParameters;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFormalParameters;
begin
  MatchCreateLeafAndPush(tkNone, cntFormalParameters);

  try
    MatchCreateLeafAndPush(tkRoundOpen);

    try
      if FLex.TokenID <> tkRoundClose then
      begin
        repeat
          BuildFormalParam;
          if FLex.TokenID = tkSemiColon then
            MatchCreateLeaf(FLex.TokenID)
          else
            Break;
        until False;
      end;
    finally
      PopLeaf;
    end;
    MatchCreateLeaf(tkRoundClose);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildFormalParam;
begin
  MatchCreateLeafAndPush(tkNone, cntFormalParam);

  try
    if FLex.TokenID in [tkVar, tkConst, tkOut] then
      MatchCreateLeaf(FLex.TokenID);
    BuildIdentList;

    if FLex.TokenID = tkColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      if FLex.TokenID = tkArray then
      begin
        MatchCreateLeaf(tkArray);
        MatchCreateLeaf(tkOf);

        if FLex.TokenID = tkRoundOpen then
        begin
          MatchCreateLeafAndPush(FLex.TokenID);
          try
            BuildSubrangeType;
          finally
            PopLeaf;
          end;
          MatchCreateLeaf(tkRoundClose);
        end
        else
        begin
          BuildConstExpression;
          if FLex.TokenID = tkDotDot then
          begin
            MatchCreateLeaf(Flex.TokenID);
            BuildConstExpression;
          end;
        end;
      end
      else if FLex.TokenID in [tkIdentifier, tkString, tkFile] then
        BuildCommonType;

      if FLex.TokenID = tkEqual then
      begin
        MatchCreateLeaf(FLex.TokenID);
        BuildConstExpression;
      end;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassHeritage;
begin
  MatchCreateLeafAndPush(tkNone, cntClassHeritage);

  try
    MatchCreateLeafAndPush(tkRoundOpen);
    try
      BuildIdentList;
    finally
      PopLeaf;
    end;
    MatchCreateLeaf(tkRoundClose);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassBody;
begin
  MatchCreateLeafAndPush(tkNone, cntClassBody);

  try
    if FLex.TokenID = tkRoundOpen then
      BuildClassHeritage;

    if FLex.TokenID <> tkSemiColon then
    begin
      BuildClassMemberList;
      MatchCreateLeaf(tkEnd);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildClassMemberList;
var
  HasVis: Boolean;
begin
  while FLex.TokenID in VisibilityTokens + ClassMemberTokens do
  begin
    HasVis := False;
    if FLex.TokenID in VisibilityTokens then
    begin
      MatchCreateLeafAndPush(FLex.TokenID);
      HasVis := True;
    end;

    try
      BuildClassMembers; // 本 Visibility 里循环 Build 多个
    finally
      if HasVis then
        PopLeaf;
    end;
  end;
end;

procedure TCnPasAstGenerator.BuildClassMembers;
begin
  while FLex.TokenID in ClassMemberTokens do
  begin
    case FLex.TokenID of
      tkProperty:
        BuildClassProperty;
      tkProcedure, tkFunction, tkConstructor, tkDestructor, tkClass:
        BuildClassMethod;
      tkType:
        BuildClassTypeSection;
      tkConst:
        BuildClassConstSection;
    else
      BuildClassField;
    end;
  end;
end;

procedure TCnPasAstGenerator.BuildClassField;
begin
  repeat
    MatchCreateLeafAndPush(tkNone, cntClassField);

    try
      BuildIdentList;
      MatchCreateLeaf(tkColon);
      BuildCommonType;
    finally
      PopLeaf;
    end;

    if FLex.TokenID = tkSemiColon then
      MatchCreateLeaf(FLex.TokenID);

    if FLex.TokenID = tkIdentifier then
      Continue
    else
      Break;
  until False;
end;

procedure TCnPasAstGenerator.BuildConstSection;
begin
  if FLex.TokenID = tkConst then
    MatchCreateLeafAndPush(tkConst)
  else if FLex.TokenID = tkResourcestring then
    MatchCreateLeafAndPush(tkResourcestring);

  try
    while FLex.TokenID = tkIdentifier do
    begin
      BuildConstDecl;
      MatchCreateLeaf(tkSemiColon);
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildConstDecl;
begin
  MatchCreateLeafAndPush(tkNone, cntConstDecl);

  try
    BuildIdent;
    if FLex.TokenID = tkEqual then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildConstExpression;
    end
    else if FLex.TokenID = tkColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildCommonType;

      MatchCreateLeaf(tkEqual);
      BuildTypedConstant;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildDirectives;
begin
  while FLex.TokenID in DirectiveTokens do
    BuildDirective;
end;

procedure TCnPasAstGenerator.BuildConstExpressionInType;
begin
  MatchCreateLeafAndPush(tkNone, cntConstExpressionInType);

  try
    BuildSimpleExpression;
    while FLex.TokenID in RelOpTokens - [tkEqual, tkGreater, tkLower] do
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildSimpleExpression;
    end;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildLibrary;
begin

end;

procedure TCnPasAstGenerator.BuildProgram;
begin
  MatchCreateLeafAndPush(tkProgram);

  try
    BuildIdent;

    if FLex.TokenID = tkRoundOpen then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildIdentList;
      MatchCreateLeaf(tkRoundClose);
    end;

    MatchCreateLeaf(tkSemiColon);
    BuildProgramBlock;

    MatchCreateLeaf(tkPoint);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildUnit;
begin
  MatchCreateLeafAndPush(tkUnit);

  try
    BuildIdent; // 不支持单元名后 platform 这种

    MatchCreateLeaf(tkSemiColon);

    BuildInterfaceSection;

    BuildImplementationSection;

    if FLex.TokenID in [tkInitialization, tkBegin] then
      BuildInitSection;

    MatchCreateLeaf(tkEnd);
    MatchCreateLeaf(tkPoint);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildProgramBlock;
begin
  while FLex.TokenID = tkUses do
    BuildUsesClause;

  while FLex.TokenID in DeclSectionTokens do
    BuildDeclSection;

  BuildCompoundStatement;
end;

procedure TCnPasAstGenerator.BuildImplementationSection;
begin

end;

procedure TCnPasAstGenerator.BuildInterfaceSection;
begin
  MatchCreateLeafAndPush(tkInterface);

  try
    while FLex.TokenID = tkUses do
      BuildUsesClause;

    while FLex.TokenID in InterfaceDeclTokens do
      BuildInterfaceDecl;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildInitSection;
begin
  MatchCreateLeafAndPush(tkInitialization);

  try
    if FLex.TokenID <> tkFinalization then
      BuildStatementList;
  finally
    PopLeaf;
  end;

  if FLex.TokenID = tkFinalization then
  begin
    MatchCreateLeafAndPush(tkFinalization);

    try
      if FLex.TokenID <> tkEnd then
        BuildStatementList;
    finally
      PopLeaf;
    end;
  end;
end;

procedure TCnPasAstGenerator.BuildDeclSection;
begin

end;

procedure TCnPasAstGenerator.BuildImplementationDecl;
begin

end;

procedure TCnPasAstGenerator.BuildInterfaceDecl;
begin
  while FLex.TokenID in InterfaceDeclTokens do
  begin
    case FLex.TokenID of
      tkConst, tkResourcestring: BuildConstSection;
      tkType: BuildTypeSection;
      tkVar, tkThreadvar: BulidVarSection;
      tkProcedure, tkFunction: BuildExportedHeading;
      tkExports: BuildExportsSection;
    end;
  end;
end;

procedure TCnPasAstGenerator.BuildCompoundStatement;
begin
  MatchCreateLeafAndPush(tkBegin); // ASM 不支持

  try
    BuildStatementList;
    MatchCreateLeaf(tkEnd);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildStatementList;
begin

end;

procedure TCnPasAstGenerator.BulidVarSection;
begin

end;

procedure TCnPasAstGenerator.BuildExportsList;
begin
  repeat
    BuildexportsDecl;
    if FLex.TokenID = tkComma then
    begin
      MatchCreateLeaf(Flex.TokenID);
      Continue;
    end
    else
      Exit;
  until False;
end;

procedure TCnPasAstGenerator.BuildExportsSection;
begin
  MatchCreateLeafAndPush(tkExports);

  try
    BuildExportsList;
    MatchCreateLeaf(tkSemiColon);
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildExportsDecl;
begin
  MatchCreateLeafAndPush(tkNone, cntExportDecl);

  try
    BuildIdent;
    if FLex.TokenID = tkRoundOpen then
      BuildFormalParameters;

    if FLex.TokenID = tkColon then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildSimpleType;
    end;
    BuildDirectives;
  finally
    PopLeaf;
  end;
end;

procedure TCnPasAstGenerator.BuildSimpleType;
begin
  if FLex.TokenID = tkRoundOpen then
    BuildSubrangeType
  else
  begin
    BuildConstExpressionInType;
    if FLex.TokenID = tkDotdot then
    begin
      MatchCreateLeaf(FLex.TokenID);
      BuildConstExpressionInType;
    end;
  end;
end;

procedure TCnPasAstGenerator.BuildExportedHeading;
begin

end;

procedure TCnPasAstGenerator.BuildDirective;
var
  CanExpr: Boolean;
begin
  if FLex.TokenID in DirectiveTokens then
  begin
    CanExpr := FLex.TokenID in DirectiveTokensWithExpressions;
    MatchCreateLeaf(FLex.TokenID);

    if CanExpr and not (FLex.TokenID in DirectiveTokens + [tkSemiColon]) then
      BuildConstExpression;
  end;
end;

end.
