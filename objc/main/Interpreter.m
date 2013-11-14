/*
 * [The "BSD license"]
 *  Copyright (c) 2011 Terence Parr and Alan Condit
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import <Foundation/Foundation.h>
#import <ANTLR/ANTLR.h>
#import <ANTLR/RuntimeException.h>
#import "STErrorListener.h"
#import "AttributeRenderer.h"
#import "Interpreter.h"
#import "Bytecode.h"
#import "BytecodeDisassembler.h"
#import "CompilationState.h"
#import "CompiledST.h"
#import "Compiler.h"
#import "FormalArgument.h"
#import "STException.h"
#import "Compiler.h"
//#import "DebugST.h"
#import "EvalExprEvent.h"
#import "EvalTemplateEvent.h"
#import "InterpEvent.h"
#import "Coordinate.h"
#import "ErrorBuffer.h"
#import "ErrorManager.h"
#import "ErrorType.h"
#import "Interval.h"
#import "DictModelAdaptor.h"
#import "Misc.h"
#import "ObjectModelAdaptor.h"
#import "STCompiletimeMessage.h"
//#import "STDump.h"
#import "STGroupCompiletimeMessage.h"
#import "STLexerMessage.h"
#import "STMessage.h"
#import "STModelAdaptor.h"
#import "STRuntimeMessage.h"
#import "Writer.h"
#import "StringWriter.h"
#import "PrintWriter.h"
#import "NoIndentWriter.h"
#import "GroupParser.h"

@implementation Interpreter_Anon1

@synthesize dict;

+ (id) newInterpreter_Anon1
{
    return [[Interpreter_Anon1 alloc] init];
}

- (id) init {
    self=[super init];
    if ( self != nil ) {
        dict = [[LinkedHashMap newLinkedHashMap:16] retain];
        [dict put:@"i0" value:[ACNumber numberWithInteger:0]];
        [dict put:@"i"  value:[ACNumber numberWithInteger:1]];
    }
    return self;
}

- (void)dealloc
{
#ifdef DEBUG_DEALLOC
    NSLog( @"called dealloc in Interpreter_Anon1" );
#endif
    if ( dict ) [dict release];
    [super dealloc];
}

- (BOOL) containsObject:(NSString *)text
{
    if ([dict get:text])
        return YES;
    return NO;
}

- (void) put:(id)key value:(id)obj
{
    [dict put:[key retain] value:[obj retain]];
}

- (id) get:(NSString *)key
{
    return [dict get:key];
}

- (NSInteger) count
{
    return [dict count];
}

- (LHMKeyIterator *) newKeyIterator
{
    return [dict newKeyIterator];
}
            
- (LHMValueIterator *) newValueIterator
{
    return [dict newValueIterator];
}

@end

@implementation Interpreter_Anon2

+ (id) newArrayWithST:(ST *)anST
{
    return [[Interpreter_Anon2 alloc] initWithST:anST];
}

- (id) initWithST:(ST *)anST
{
    self=[super initWithCapacity:5];
    if ( self != nil ) {
        [self addObject:anST];
    }
    return self;
}

@end

@implementation Interpreter_Anon3
@synthesize Option;

+ (OptionEnum) ANCHOR
{
    return ANCHOR;
}

+ (OptionEnum) FORMAT
{
    return FORMAT;
}

+ (OptionEnum) _NULL
{
    return _NULL;
}

+ (OptionEnum) SEPARATOR
{
    return SEPARATOR;
}

+ (OptionEnum) WRAP
{
    return WRAP;
}

+ (id) newInterpreter_Anon3
{
    return [[Interpreter_Anon3 alloc] init];
}

- (id) init
{
    self=[super init];
    return self;
}

- (OptionEnum) ANCHOR
{
    return ANCHOR;
}

- (OptionEnum) FORMAT
{
    return FORMAT;
}

- (OptionEnum) _NULL
{
    return _NULL;
}

- (OptionEnum) SEPARATOR
{
    return SEPARATOR;
}

- (OptionEnum) WRAP
{
    return WRAP;
}

- (OptionEnum) containsObject:(NSString *)text
{
    if (text) {
        if ([text isEqualToString:@"anchor"])
            return ANCHOR;
        else if ([text isEqualToString:@"format"])
            return FORMAT;
        else if ([text isEqualToString:@"null"])
            return _NULL;
        else if ([text isEqualToString:@"separator"])
            return SEPARATOR;
        else if ([text isEqualToString:@"wrap"])
            return WRAP;
    }
    return -1;
}

- (NSInteger) count
{
    return 5;
}

@end

OptionEnum OptionValueOf(NSString *text)
{
    if (text) {
        if ([text isEqualToString:@"anchor"])
            return ANCHOR;
        else if ([text isEqualToString:@"format"])
            return FORMAT;
        else if ([text isEqualToString:@"null"])
            return _NULL;
        else if ([text isEqualToString:@"separator"])
            return SEPARATOR;
        else if ([text isEqualToString:@"wrap"])
            return WRAP;
    }
    return -1;
}

NSString *OptionDescription(OptionEnum value)
{
    switch (value) {
        case ANCHOR:
            return @"anchor";
        case FORMAT:
            return @"format";
        case _NULL:
            return @"null";
        case SEPARATOR:
            return @"separator";
        case WRAP:
            return @"wrap";
    }
    return nil;
}

#define DEF_INSTR_LOAD_STR 1
#define DEF_INSTR_LOAD_ATTR 2
#define DEF_INSTR_LOAD_LOCAL 3
#define DEF_INSTR_LOAD_PROP 4
#define DEF_INSTR_LOAD_PROP_IND 5
#define DEF_INSTR_STORE_OPTION 6
#define DEF_INSTR_STORE_ARG 7
#define DEF_INSTR_NEW 8
#define DEF_INSTR_NEW_IND 9
#define DEF_INSTR_NEW_BOX_ARGS 10
#define DEF_INSTR_SUPER_NEW 11
#define DEF_INSTR_SUPER_NEW_BOX_ARGS 12
#define DEF_INSTR_WRITE 13
#define DEF_INSTR_WRITE_OPT 14
#define DEF_INSTR_MAP 15
#define DEF_INSTR_ROT_MAP 16
#define DEF_INSTR_ZIP_MAP 17
#define DEF_INSTR_BR 18
#define DEF_INSTR_BRF 19
#define DEF_INSTR_OPTIONS 20
#define DEF_INSTR_ARGS 21
#define DEF_INSTR_PASSTHRU 22
#define DEF_INSTR_PASSTHRU_IND 23
#define DEF_INSTR_LIST 24
#define DEF_INSTR_ADD 25
#define DEF_INSTR_TOSTR 26
#define DEF_INSTR_FIRST 27
#define DEF_INSTR_LAST 28
#define DEF_INSTR_REST 29
#define DEF_INSTR_TRUNC 30
#define DEF_INSTR_STRIP 31
#define DEF_INSTR_TRIM 32
#define DEF_INSTR_LENGTH 33
#define DEF_INSTR_STRLEN 34
#define DEF_INSTR_REVERSE 35
#define DEF_INSTR_NOT 36
#define DEF_INSTR_OR 37
#define DEF_INSTR_AND 38
#define DEF_INSTR_INDENT 39
#define DEF_INSTR_DEDENT 40
#define DEF_INSTR_NEWLINE 41
#define DEF_INSTR_NOOP 42
#define DEF_INSTR_POP 43
#define DEF_INSTR_NULL 44
#define DEF_INSTR_TRUE 45
#define DEF_INSTR_FALSE 46
#define DEF_INSTR_WRITE_STR 47
#define DEF_INSTR_WRITE_LOCAL 48

#define DEF_MAX_BYTECODE 48

/** This class knows how to execute template bytecodes relative to a
 *  particular STGroup. To execute the byte codes, we need an output stream
 *  and a reference to an ST an instance. That instance's impl field points at
 *  a CompiledST, which contains all of the byte codes and other information
 *  relevant to execution.
 *
 *  This interpreter is a stack-based bytecode interpreter.  All operands
 *  go onto an operand stack.
 *
 *  If the group that we're executing relative to has debug set, we track
 *  interpreter events. For now, I am only tracking instance creation events.
 *  These are used by STViz to pair up output chunks with the template
 *  expressions that generate them.
 *
 *  We create a new interpreter for each ST.render(), DebugST.inspect, or
 *  DebugST.getEvents() invocation.
 */

@implementation Interpreter

#ifdef USE_FREQ_COUNT
static NSInteger count[DEF_MAX_BYTECODE+1];
#endif
static LinkedHashMap *predefinedAnonSubtemplateAttributes;
static Interpreter_Anon3 *Option;
//static OptionEnum Option;
static NSInteger DEFAULT_OPERAND_STACK_SIZE;
/** Dump bytecode instructions as we execute them? mainly for parrt */
static BOOL trace = NO;
/** Track events inside templates and in this.events */

//@synthesize operands;
@synthesize sp;
@synthesize current_ip;
@synthesize nwline;
@synthesize group;
@synthesize locale;
@synthesize errMgr;
@synthesize events;
@synthesize executeTrace;
@synthesize debugInfo;
@synthesize debug;

+ (void) initialize
{
    Interpreter_Anon1 *tmp = [Interpreter_Anon1 newInterpreter_Anon1];
    predefinedAnonSubtemplateAttributes = [tmp.dict retain];
    Option = [Interpreter_Anon3 newInterpreter_Anon3];
    DEFAULT_OPERAND_STACK_SIZE = 100;
}

+ (NSInteger) DEFAULT_OPERAND_STACK_SIZE
{
    return DEFAULT_OPERAND_STACK_SIZE;
}

+ (LinkedHashMap *)predefinedAnonSubtemplateAttributes
{
    return predefinedAnonSubtemplateAttributes;
}

+ (Interpreter_Anon3 *) Option
{
    return Option;
}

+ (id) newInterpreter:(STGroup *)aGroup locale:(NSLocale *)aLocale debug:(BOOL)aDebug
{
    return [[Interpreter alloc] init:aGroup locale:aLocale debug:aDebug];
}

+ (id) newInterpreter:(STGroup *)aGroup locale:(NSLocale *)aLocale errMgr:(ErrorManager *)anErrMgr debug:(BOOL)aDebug
{
    return [[Interpreter alloc] init:aGroup locale:aLocale errMgr:anErrMgr debug:aDebug];
}

- (id) initWithGroup:(STGroup *)aGroup debug:(BOOL)aDebug
{
    self = [self init:aGroup locale:[NSLocale currentLocale] errMgr:aGroup.errMgr debug:aDebug];
    return self;
}

- (id) init:(STGroup *)aGroup locale:(NSLocale *)aLocale debug:(BOOL)aDebug
{
    self = [self init:aGroup locale:aLocale errMgr:aGroup.errMgr debug:aDebug];
    return self;
}

- (id) init:(STGroup *)aGroup errMgr:(ErrorManager *)anErrMgr debug:(BOOL)aDebug
{
    self = [self init:aGroup locale:[NSLocale currentLocale] errMgr:anErrMgr debug:aDebug];
    return self;
}

- (id) init:(STGroup *)aGroup locale:(NSLocale *)aLocale errMgr:(ErrorManager *)anErrMgr debug:(BOOL)aDebug
{
    self=[super init];
    if ( self != nil ) {
        //operands = [AMutableArray arrayWithCapacity:10];
        sp = -1;        // stack pointer register
        current_ip = 0; // mirrors ip in exec(), but visible to all methods
        nwline = 0;     // how many char written on this template LINE so far?
        group = aGroup;
        if ( group ) [group retain];
        locale = aLocale;
        if ( locale ) [locale retain];
        errMgr = anErrMgr;
        if ( errMgr ) [errMgr retain];
        debug = aDebug;
        if (debug) {
            events = [[AMutableArray arrayWithCapacity:5] retain];
//            executeTrace = [AMutableArray arrayWithCapacity:10];
            debugInfo = [[LinkedHashMap newLinkedHashMap:5] retain];
        }
    }
    return self;
}

- (void)dealloc
{
#ifdef DEBUG_DEALLOC
    NSLog( @"called dealloc in Interpreter" );
#endif
    if ( group ) [group release];
    if ( locale ) [locale release];
    if ( errMgr ) [errMgr release];
    if ( executeTrace ) [executeTrace release];
    if ( events ) [events release];
    if ( debugInfo ) [debugInfo release];
    [super dealloc];
}

#ifdef USE_FREQ_COUNT
- (void) dumpOpcodeFreq
{
    NSLog(@"#### instr freq:");
    for (int i=1; i <= Bytecode.MAX_BYTECODE; i++) {
        NSLog(@"%d %@", count[i], Bytecode.instructions[i].name);
    }
}
#endif

/** Execute template self and return how many characters it wrote to out */
- (NSInteger) exec:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope
{
    if ( debug ) NSLog( @"[self exec:[aWho getName]]\n" );
    @try {
        [self setDefaultArguments:anSTWriter scope:aScope];
        NSInteger n = [self _exec:anSTWriter scope:aScope];
        return n;
    }
    @catch (NSException *e) {
        StringWriter *sw = [[StringWriter newWriter] retain];
/*
        PrintWriter *pw = [[PrintWriter newWriter:sw] retain];
        [e printStackTrace:pw];
        [pw flush];
 */
        [errMgr runTimeError:self
                       scope:aScope
                       error:INTERNAL_ERROR
                         arg:[NSString stringWithFormat:@"internal error caused by: %@ : %@ : %@",[e name], [e reason], [sw description]]];
        return 0;
    }
}
/**
 * Execute template self and return how many characters it wrote to out
 */
- (NSInteger) _exec:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope
{
    ST *aWho = aScope.st;
    NSInteger start = [anSTWriter index];
    NSInteger prevOpcode = 0;
    NSInteger n = 0;
    NSInteger n1 = 0;
    NSInteger idx;
    NSInteger nargs;
    NSInteger nameIndex;
    NSInteger optionIndex;
    NSInteger addr;
    NSInteger nmaps;
    NSString *name;
    NSInteger valueIndex;
    id obj;
    id left;
    id right;
    id propName;
    ST *st;
    AMutableArray *options;
    MemBuffer *code = aWho.impl.instrs;        // which code block are we executing
 //    NSLog( @"%@\n", [aWho.impl.instrs description] );
 //    [aWho.impl dump];
    short opcode;
    NSInteger ip = 0;
    while ( ip < aWho.impl.codeSize ) {
        if (trace || debug) [self trace:aScope ip:ip];
        opcode = [code charAtIndex:ip];
        //count[opcode]++;
        aScope.ret_ip = ip;
        ip++; //jump to next instruction or first byte of operand
        switch (opcode) {
            case  DEF_INSTR_LOAD_STR:
                // just testing...
                [self load_str:aWho ip:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                break;
            case  DEF_INSTR_LOAD_ATTR:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                @try {
                    obj = [self getAttribute:aScope name:name];
                    if ( obj == ST.EMPTY_ATTR ) obj = nil;
                }
                @catch (STNoSuchAttributeException *nsae) {
                    [errMgr runTimeError:self scope:aScope error:NO_SUCH_ATTRIBUTE arg:name];
                    obj = nil;
                }
                operands[++sp] = obj;
                break;
            case  DEF_INSTR_LOAD_LOCAL:
                valueIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = [aWho.locals objectAtIndex:valueIndex];
                if ( obj == ST.EMPTY_ATTR )
                    obj = nil;
                operands[++sp] = obj;
                break;
            case  DEF_INSTR_LOAD_PROP:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = operands[sp--];
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                operands[++sp] = [self getObjectProperty:anSTWriter scope:aScope obj:obj property:name];
                break;
            case  DEF_INSTR_LOAD_PROP_IND:
                propName = operands[sp--];
                obj = operands[sp];
                operands[sp] = [self getObjectProperty:anSTWriter scope:aScope obj:obj property:propName];
                break;
            case  DEF_INSTR_NEW:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                nargs = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                // look up in original hierarchy not enclosing template (variable group)
                // see TestSubtemplates.testEvalSTFromAnotherGroup()
                st = [aWho.groupThatCreatedThisInstance getEmbeddedInstanceOf:self scope:aScope name:name];
                // get n args and store into st's attr list
                [self storeArgs:aScope nargs:nargs st:st];
                sp -= nargs;
                operands[++sp] = st;
                break;
            case  DEF_INSTR_NEW_IND:
                nargs = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = (NSString *)operands[sp - nargs];
                st = [aWho.groupThatCreatedThisInstance getEmbeddedInstanceOf:self scope:aScope name:name];
                [self storeArgs:aScope nargs:nargs st:st];
                sp -= nargs;
                sp--;
                operands[++sp] = st;
                break;
            case  DEF_INSTR_NEW_BOX_ARGS:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                LinkedHashMap *attrs = (LinkedHashMap *)operands[sp--];
                // look up in original hierarchy not enclosing template (variable group)
                // see TestSubtemplates.testEvalSTFromAnotherGroup()
                st = [aWho.groupThatCreatedThisInstance getEmbeddedInstanceOf:self scope:aScope name:name];
                // get n args and store into st's attr list
                [self storeArgs:aScope attrs:attrs st:st];
                 operands[++sp] = st;
                break;
// start here checking
            case  DEF_INSTR_SUPER_NEW:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                nargs = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                [self super_new:aScope name:name nargs:nargs];
                break;
            case  DEF_INSTR_SUPER_NEW_BOX_ARGS:
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                attrs = (LinkedHashMap *)operands[sp--];
                [self super_new:aScope name:name attrs:attrs];
                break;
            case  DEF_INSTR_STORE_OPTION:
                optionIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = operands[sp--];
                options = (AMutableArray *)operands[sp];
                [options replaceObjectAtIndex:optionIndex withObject:obj];
                break;
            case  DEF_INSTR_STORE_ARG:
                nameIndex = [code shortAtIndex:ip];
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = operands[sp--];
                attrs = (LinkedHashMap *)operands[sp];
                [attrs put:name value:obj];
                break;
            case  DEF_INSTR_WRITE:
                obj = operands[sp--];
                idx = [self writeObjectNoOptions:anSTWriter scope:aScope obj:obj];
                n += idx;
                nwline += idx;
                break;
            case  DEF_INSTR_WRITE_OPT:
                options = (AMutableArray *)operands[sp--]; // get options
                obj = operands[sp--];                      // get option to write
                idx = [self writeObjectWithOptions:anSTWriter scope:aScope obj:obj options:options];
                n += idx;
                nwline += idx;
                break;
            case  DEF_INSTR_MAP:
                st = (ST *)operands[sp--]; // get prototype off stack
                obj = operands[sp--];      // get object to map prototype across
                [self map:aScope attr:obj st:st];
                break;
            case  DEF_INSTR_ROT_MAP:
                nmaps = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                AMutableArray *templates = [[AMutableArray arrayWithCapacity:5] retain];
                for (NSInteger i = nmaps - 1; i >= 0; i--)
                    [templates addObject:(ST *)(operands[sp - i])];
                sp -= nmaps;
                obj = operands[sp--];
                if (obj != nil && obj != [NSNull null] )
                    [self rot_map:aScope attr:obj prototypes:templates];
                break;
            case  DEF_INSTR_ZIP_MAP:
                st = (ST *)operands[sp--];
                nmaps = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                AMutableArray *exprs = [AMutableArray arrayWithCapacity:5];
                for (NSInteger i = nmaps - 1; i >= 0; i--) {
                    obj = (operands[sp - i]);
                    [exprs addObject:obj];
                }
                sp -= nmaps;
                operands[++sp] = [self zip_map:aScope exprs:exprs prototype:st];
                break;
            case  DEF_INSTR_BR:
                ip = [code shortAtIndex:ip];
                break;
            case  DEF_INSTR_BRF:
                addr = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = operands[sp--];
                if ( ![self testAttributeTrue:obj] ) ip = addr; // jump
                break;
            case  DEF_INSTR_OPTIONS:
                 operands[++sp] = [[AMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil] retain];
                break;
            case  DEF_INSTR_ARGS:
                 operands[++sp] = [[LinkedHashMap newLinkedHashMap:5] retain];
                break;
            case DEF_INSTR_PASSTHRU :
                nameIndex = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                name = [aWho.impl.strings objectAtIndex:nameIndex];
                attrs = (LinkedHashMap *)operands[sp];
                [self passthru:aScope templateName:name attrs:attrs];
                break;
            case  DEF_INSTR_LIST:
                operands[++sp] = [[AMutableArray arrayWithCapacity:5] retain];
                break;
            case  DEF_INSTR_ADD:
                obj = operands[sp--];
                AMutableArray *list = (AMutableArray *)operands[sp];
                [self addToList:aScope list:list obj:obj];
                break;
            case  DEF_INSTR_TOSTR:
                // replace with string value; early eval
                operands[sp] = [self description:anSTWriter scope:aScope value:operands[sp]];
                break;
            case  DEF_INSTR_FIRST:
                operands[sp] = [self first:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_LAST:
                operands[sp] = [self last:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_REST:
                operands[sp] = [self rest:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_TRUNC:
                operands[sp] = [self trunc:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_STRIP:
                operands[sp] = [self strip:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_TRIM:
                obj = operands[sp--];
                if ([obj isKindOfClass:[NSString class]]) {
                    operands[++sp] = [((NSString *)obj) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                else {
                    [errMgr runTimeError:self scope:aScope error:EXPECTING_STRING arg:@"trim" arg2:[obj className]];
                    operands[++sp] = obj;
                }
                break;
            case  DEF_INSTR_LENGTH:
                obj = operands[sp];
                operands[sp] = (id)[NSString stringWithFormat:@"%d", [self length:operands[sp]]];
                break;
            case  DEF_INSTR_STRLEN:
                obj = operands[sp--];
                if ([obj isKindOfClass:[NSString class]]) {
                    operands[++sp] = (id)[NSString stringWithFormat:@"%d", [((NSString *)obj) length]];
                }
                else {
                    [errMgr runTimeError:self scope:aScope error:EXPECTING_STRING arg:@"strlen" arg2:[obj className]];
                    operands[++sp] = @"0";
                }
                break;
            case  DEF_INSTR_REVERSE:
                operands[sp] = [self reverse:aScope obj:operands[sp]];
                break;
            case  DEF_INSTR_NOT:
                operands[sp] = (id)(![self testAttributeTrue:operands[sp]]);
                break;
            case  DEF_INSTR_OR:
                right = operands[sp--];
                left = operands[sp--];
                operands[++sp] = (id)([self testAttributeTrue:left] || [self testAttributeTrue:right]);
                break;
            case  DEF_INSTR_AND:
                right = operands[sp--];
                left = operands[sp--];
                operands[++sp] = (id)([self testAttributeTrue:left] && [self testAttributeTrue:right]);
                break;
            case  DEF_INSTR_INDENT:
                idx = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                [self indent:anSTWriter scope:aScope index:idx];
//                [anSTWriter pushIndentation:[aWho.impl.strings objectAtIndex:idx]];
                break;
            case  DEF_INSTR_DEDENT:
                [anSTWriter popIndentation];
                break;
            case  DEF_INSTR_NEWLINE:
                
                @try {
                    if ( prevOpcode ==  DEF_INSTR_NEWLINE ||
                         prevOpcode ==  DEF_INSTR_INDENT  ||
                         nwline > 0 ) {
                        [anSTWriter writeStr:Misc.newline];
                    }
                    nwline = 0;
                }
                @catch (IOException *ioe) {
                    [errMgr IOError:aWho error:WRITE_IO_ERROR e:ioe];
                }
                break;
            case  DEF_INSTR_NOOP:
                break;
            case  DEF_INSTR_POP:
                sp--;
                break;
            case  DEF_INSTR_NULL:
                 operands[++sp] = nil;
                break;
            case DEF_INSTR_TRUE:
                operands[++sp] = [ACNumber numberWithBool:YES];
                break;
            case DEF_INSTR_FALSE :
                operands[++sp] = [ACNumber numberWithBool:NO];
                break;
            case DEF_INSTR_WRITE_STR :
                idx = [code shortAtIndex:ip];
                ip += Bytecode.OPND_SIZE_IN_BYTES;
                obj = [aWho.impl.strings objectAtIndex:idx];
                n1 = [self writeObjectNoOptions:anSTWriter scope:aScope obj:obj];
                n += n1;
                nwline += n1;
                break;
//            case DEF_INSTR_WRITE_LOCAL:
//                idx = [code shortAtIndex:ip];
//                ip += Bytecode.OPND_SIZE_IN_BYTES;
//                obj = [aWho.locals objectAtIndex:idx];
//                if ( obj==ST.EMPTY_ATTR ) obj = nil;
//                n1 = [self writeObjectNoOptions:anSTWriter scope:aScope obj:obj];
//                n += n1;
//                nwline += n1;
//                break;
            default:
                [errMgr internalError:aWho msg:[NSString stringWithFormat:@"invalid bytecode @ %d:%d", ip - 1, opcode] e:nil];
                [aWho.impl dump];
                break;
        }
        prevOpcode = opcode;
    }
    
    if ( debug ) {
        NSInteger stop = [anSTWriter index] - 1;
        EvalTemplateEvent *e = [EvalTemplateEvent newEvent:(InstanceScope *)aScope start:start stop:stop];
        [self trackDebugEvent:aScope event:e];
    }
    return n;
}

- (void) load_str:(ST *)who ip:(NSInteger)ip
{
    int strIndex = [who.impl.instrs shortAtIndex:ip];
    ip += Bytecode.OPND_SIZE_IN_BYTES;
    operands[++sp] = [who.impl.strings objectAtIndex:strIndex];
}

// TODO: refactor to remove dup'd code
- (void) super_new:(InstanceScope *)aScope name:(NSString *)name nargs:(NSInteger)nargs
{
    ST *st = nil;
    CompiledST *imported = [aScope.st.impl.nativeGroup lookupImportedTemplate:name];
    if (imported == nil) {
        [errMgr runTimeError:self scope:aScope error:NO_IMPORTED_TEMPLATE arg:name];
        st = [aScope.st.groupThatCreatedThisInstance createStringTemplateInternally:[CompiledST newCompiledST]];
    }
    else {
        st = [imported.nativeGroup getEmbeddedInstanceOf:self scope:aScope name:name];
        st.groupThatCreatedThisInstance = group;
    }
    [self storeArgs:aScope nargs:nargs st:st];
    sp -= nargs;
    operands[++sp] = st;
}

- (void) super_new:(InstanceScope *)aScope name:(NSString *)name attrs:(LinkedHashMap *)attrs
{
    ST *st = nil;
    CompiledST *imported = [aScope.st.impl.nativeGroup lookupImportedTemplate:name];
    if (imported == nil) {
        [errMgr runTimeError:self scope:aScope error:NO_IMPORTED_TEMPLATE arg:name];
        st = [aScope.st.groupThatCreatedThisInstance createStringTemplateInternally:[CompiledST newCompiledST]];
    }
    else {
        st = [imported.nativeGroup createStringTemplateInternally:imported];
        st.groupThatCreatedThisInstance = group;
    }

    // get n args and store into st's attr list
    [self storeArgs:aScope attrs:attrs st:st];
    operands[++sp] = st;
}

- (void) passthru:(InstanceScope *)aScope templateName:(NSString *)templateName attrs:(LinkedHashMap *)attrs
{
    CompiledST *c = [group lookupTemplate:templateName];
    if ( c == nil ) return; // will get error later
    if ( c.formalArguments == nil ) return;
    id obj;
//    for (FormalArgument *arg in [c.formalArguments allValues]) {
    FormalArgument *arg;
    LHMValueIterator *it = (LHMValueIterator *)[c.formalArguments newValueIterator];
    while ( [it hasNext] ) {
        arg = (FormalArgument *)[it next];
        if ( [attrs get:arg.name] == nil ) {
            @try {
                obj = [self getAttribute:aScope name:arg.name];
                // If the attribute exists but there is no value and
                // the formal argument has no default value, make it null.
                if ( obj == ST.EMPTY_ATTR && arg.defaultValueToken == nil ) {
                    [attrs put:arg.name value:nil];
                }
                else if ( obj != ST.EMPTY_ATTR ) {
                    [attrs put:arg.name value:obj];
                }
            }
            @catch (STNoSuchAttributeException *nsae) {
                // if no such attribute exists for arg.name, set parameter
                // if no default value
                if ( arg.defaultValueToken == nil ) {
                    [errMgr runTimeError:self scope:aScope error:NO_SUCH_ATTRIBUTE_PASS_THROUGH arg:arg.name];
                    [attrs put:arg.name value:nil];
                }
            }
        }
    }
    [it release];
}

- (void) storeArgs:(InstanceScope *)aScope attrs:(LinkedHashMap *)attrs st:(ST *)st
{
    if ( (attrs!=nil) && ([attrs count] > 0) &&
        !st.impl.hasFormalArgs && st.impl.formalArguments==nil )
    {
        [st add:ST.IMPLICIT_ARG_NAME value:nil]; // pretend we have "it" arg
    }
    NSInteger nformalArgs = ( st.impl.formalArguments == nil ) ? 0 : [st.impl.formalArguments count];
    NSInteger nargs = ( attrs == nil ) ? 0 : [attrs count];
    if ( nargs < (nformalArgs - st.impl.numberOfArgsWithDefaultValues) ||
        nargs > nformalArgs ) {
        [errMgr runTimeError:self
                       scope:aScope
                       error:ARGUMENT_COUNT_MISMATCH
                         arg:[ACNumber numberWithInteger:nargs]
                        arg2:st.impl.name
                        arg3:[ACNumber numberWithInteger:nformalArgs]];
    }
    NSString *argName;
/*
    for ( argName in [attrs allKeys] ) {
 */
    LHMKeyIterator *it = (LHMKeyIterator *)[attrs newKeyIterator];
    while ( [it hasNext] ) {
        argName = (NSString *)[it next];
        if ( st.impl.formalArguments == nil ||
            [st.impl.formalArguments get:argName] == nil ) {
            [errMgr runTimeError:self
                           scope:aScope
                           error:NO_SUCH_ATTRIBUTE
                             arg:argName];
            continue;
        }
        id obj = [attrs get:argName];
        [st rawSetAttribute:argName value:obj];
    }
    [it release];
}

- (void) storeArgs:(InstanceScope *)aScope nargs:(NSInteger)nargs st:(ST *)st
{
    if ( nargs > 0 && !st.impl.hasFormalArgs && st.impl.formalArguments==nil ) {
        [st add:ST.IMPLICIT_ARG_NAME value:nil]; // pretend we have "it" arg
    }
    NSInteger nformalArgs = ( st.impl.formalArguments == nil ) ? 0 : [st.impl.formalArguments count];
    NSInteger firstArg = sp - (nargs - 1);
    NSInteger numToStore = (nargs < nformalArgs) ? nargs : nformalArgs;
    if ( st.impl.isAnonSubtemplate )
        nformalArgs -= [predefinedAnonSubtemplateAttributes count];
    if ( nargs < (nformalArgs - st.impl.numberOfArgsWithDefaultValues) ||
        nargs > nformalArgs )
    {
        [errMgr runTimeError:self
                       scope:aScope
                       error:ARGUMENT_COUNT_MISMATCH
                         arg:[ACNumber numberWithInteger:nargs]
                        arg2:st.impl.name
                        arg3:[ACNumber numberWithInteger:nformalArgs]];
    }
    if ( st.impl.formalArguments == nil ) return;

    LHMKeyIterator *argNames = (LHMKeyIterator *)[st.impl.formalArguments newKeyIterator];
    id obj;
    for (NSInteger i = 0; i < numToStore; i++) {
        obj = operands[firstArg + i];
        NSString *argName = [argNames next];
        [st rawSetAttribute:argName value:obj];
    }
}

- (void) indent:(id<STWriter>)wr1 scope:(InstanceScope *)aScope index:(NSInteger)strIndex
{
    NSString *indent = [aScope.st.impl.strings objectAtIndex:strIndex];
    if ( debug ) {
        NSInteger aStart = [wr1 index]; // track char we're about to write
        EvalExprEvent *e = [EvalExprEvent newEvent:aScope
                                             start:aStart
                                              stop:aStart + [indent length] - 1
                                         exprStart:[self getExprStartChar:aScope]
                                          exprStop:[self getExprStopChar:aScope]];
        [self trackDebugEvent:aScope event:e];
    }
    [wr1 pushIndentation:indent];
}

/** Write out an expression result that doesn't use expression options.
 *  E.g., <name>
 */
- (NSInteger) writeObjectNoOptions:(id<STWriter>)wr1 scope:(InstanceScope *)aScope obj:(id)obj
{
    if ( wr1 == nil ) @throw [NSException exceptionWithName:@"Cant send msg to nil" reason:@"wr1 is nil" userInfo:nil];
    NSInteger aStart = [wr1 index]; // track char we're about to write
    NSInteger n = [self writeObject:wr1 scope:aScope obj:obj options:nil];
    if ( debug ) {
        EvalExprEvent *e = [EvalExprEvent newEvent:aScope
                                             start:aStart
                                              stop:[wr1 index] - 1
                                         exprStart:[self getExprStartChar:aScope]
                                          exprStop:[self getExprStopChar:aScope]];
        [self trackDebugEvent:aScope event:e];
    }
    return n;
}

/** Write out an expression result that uses expression options.
 *  E.g., <names; separator=", ">
 */
- (NSInteger) writeObjectWithOptions:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope obj:(id)obj options:(AMutableArray *)options
{
    NSInteger start = [anSTWriter index];
    // precompute all option values (render all the way to strings)
    AMutableArray *optionStrings = nil;
    if (options != nil) {
        optionStrings = [[AMutableArray arrayWithObjects:@"", @"", @"", @"",@"", nil] retain];
        for (NSInteger i = 0; i < Compiler.NUM_OPTIONS; i++) {
            id obj = [self description:anSTWriter scope:aScope value:[options objectAtIndex:i]];
            [optionStrings replaceObjectAtIndex:i withObject:obj];
        }
    }
    if ( options != nil && [options objectAtIndex:Interpreter.Option.ANCHOR] != nil) {
        [anSTWriter pushAnchorPoint];
    }

    NSInteger n = [self writeObject:anSTWriter scope:aScope obj:obj options:optionStrings];

    if ( options != nil && [options objectAtIndex:Interpreter.Option.ANCHOR] != nil ) {
        [anSTWriter popAnchorPoint];
    }
    if ( debug ) {
        EvalExprEvent *e = [EvalExprEvent newEvent:aScope
                                             start:start stop:[anSTWriter index]-1
                                         exprStart:[self getExprStartChar:aScope]
                                          exprStop:[self getExprStopChar:aScope]];
        [self trackDebugEvent:aScope event:e];
    }
    return n;
}

/** Generic method to emit text for an object. It differentiates
 *  between templates, iterable objects, and plain old Java objects (POJOs)
 */
- (NSInteger) writeObject:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope obj:(id)obj options:(AMutableArray *)options
{
    NSInteger n = 0;
    if ( obj == nil ) {
        if ( options != nil && [options objectAtIndex:Interpreter.Option._NULL] != nil ) {
            obj = [options objectAtIndex:Interpreter.Option._NULL];
        }
        else {
            return 0;
        }
    }
    ST *st = obj;
    if ( [obj isKindOfClass:[ST class]] ) {
        aScope = [InstanceScope newInstanceScope:aScope who:st];
        if ( options != nil && [options objectAtIndex:Interpreter.Option.WRAP] != nil ) {
            // if we have a wrap string, then inform writer it
            // might need to wrap
            @try {
                [anSTWriter writeWrap:[options objectAtIndex:Interpreter.Option.WRAP]];
            }
            @catch (IOException *ioe) {
                [errMgr IOError:aScope.st error:WRITE_IO_ERROR e:ioe];
            }
        }
        n = [self exec:anSTWriter scope:aScope];
    }
    else {
        obj = [self convertAnythingIteratableToIterator:aScope attribute:obj]; // normalize
        
        @try {
            if ( [obj isKindOfClass:[ArrayIterator class]] )
                n = [self writeIterator:anSTWriter scope:aScope obj:obj options:options];
            else
                n = [self writePOJO:anSTWriter scope:aScope obj:obj options:options];
        }
        @catch (IOException *ioe) {
            [errMgr IOError:aScope.st error:WRITE_IO_ERROR e:ioe arg:obj];
        }
    }
    return n;
}

- (NSInteger) writeIterator:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope obj:(id)obj options:(AMutableArray *)options
{
    if ( obj == nil ) return 0;
    NSInteger n = 0;
    NSString *separator = nil;
    if ( options != nil )
        separator = [options objectAtIndex:Interpreter.Option.SEPARATOR];
    BOOL seenAValue = NO;
    id iterValue;
    ArrayIterator *it = (ArrayIterator *)obj;
    [it retain];
    while ( [it hasNext] ) {
        iterValue = [it nextObject];
        // Emit separator if we're beyond first value
        if ( iterValue == [NSNull null] ) iterValue = nil;
        BOOL needSeparator = seenAValue &&
                             separator != nil &&
                             ( iterValue != nil ||
                               [options objectAtIndex:Interpreter.Option._NULL] != nil);
        if ( needSeparator )
            n += [anSTWriter writeSeparator:separator];
        NSInteger nw = [self writeObject:anSTWriter scope:aScope obj:iterValue options:options];
        if ( nw > 0 )
            seenAValue = YES;
        n += nw;
    }
    [it release];
    it = nil;
    return n;
}

- (NSInteger) writePOJO:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope obj:(id)obj options:(AMutableArray *)options {
    NSString *formatString = nil;
    NSString *v;
    id<AttributeRenderer> r = nil;
    if (options != nil)
        formatString = [options objectAtIndex:Interpreter.Option.FORMAT];
    r = [aScope.st.impl.nativeGroup getAttributeRenderer:[obj class]];
    if ( r != nil )
        v = [r description:obj formatString:formatString locale:locale];
    else {
        v = [obj description];
    }
    NSInteger n;
    if ( options != nil && [options objectAtIndex:Interpreter.Option.WRAP] != nil ) {
        n = [anSTWriter write:v wrap:[options objectAtIndex:Interpreter.Option.WRAP]];
    }
    else {
        n = [anSTWriter writeStr:v];
    }
    return n;
}

- (NSInteger) getExprStartChar:(InstanceScope *)aScope
{
    Interval *templateLocation = [aScope.st.impl.sourceMap objectAtIndex:aScope.ret_ip];
    if ( templateLocation != nil ) return templateLocation.a;
    return -1;
}

- (NSInteger) getExprStopChar:(InstanceScope *)aScope
{
    Interval *templateLocation = [aScope.st.impl.sourceMap objectAtIndex:aScope.ret_ip];
    if ( templateLocation != nil ) return templateLocation.b;
    return -1;
}

- (void) map:(InstanceScope *)aScope attr:(id)attr st:(ST *)st
{
    [self rot_map:aScope attr:attr prototypes:[Interpreter_Anon2 newArrayWithST:st]];
}

- (void) rot_map:(InstanceScope *)aScope attr:(id)attr prototypes:(AMutableArray *)prototypes
{
    if ( attr == nil ) {
        operands[++sp] = nil;
        return;
    }
    attr = [self convertAnythingIteratableToIterator:aScope attribute:attr];
    if ( [attr isKindOfClass:[ArrayIterator class]] ) {
        AMutableArray *mapped = [self rot_map_iterator:aScope iter:attr proto:prototypes];
        operands[++sp] = mapped;
    }
    else {
        ST *proto = [prototypes objectAtIndex:0];
        ST *st = [group createStringTemplateInternallyWithProto:proto];
        if ( st != nil ) {
            [self setFirstArgument:aScope st:st attr:attr];
            if ( st.impl.isAnonSubtemplate ) {
                [st rawSetAttribute:@"i0" value:[ACNumber numberWithInteger:0]];
                [st rawSetAttribute:@"i" value:[ACNumber numberWithInteger:1]];
            }
            operands[++sp] = st;
        }
        else {
            operands[++sp] = nil;
        }
    }
}

- (AMutableArray *) rot_map_iterator:(InstanceScope *)aScope iter:(id)attr proto:(AMutableArray *)prototypes
{
    AMutableArray *mapped = [[AMutableArray arrayWithCapacity:5] retain];
    NSInteger i0 = 0;
    NSInteger i = 1;
    NSInteger ti = 0;
    id iterValue;
    
    ArrayIterator *it = (ArrayIterator *)attr;
    [it retain];
    while ( [it hasNext] ) {
        iterValue = [it nextObject];
        if ( iterValue == nil || iterValue == [NSNull null] ) {
            [mapped addObject:nil];
            continue;
        }
        NSInteger templateIndex = ti % [prototypes count];
        ti++;
        ST *proto = [prototypes objectAtIndex:templateIndex];
        ST *st = [group createStringTemplateInternallyWithProto:proto];
        [self setFirstArgument:aScope st:st attr:iterValue];
        if ( st.impl.isAnonSubtemplate ) {
            [st rawSetAttribute:@"i0" value:[ACNumber numberWithInteger:i0]];
            [st rawSetAttribute:@"i" value:[ACNumber numberWithInteger:i]];
        }
        [mapped addObject:st];
        i0++;
        i++;
    }
    [it release];
    it = nil;
    return mapped;
}

// <names,phones:{n,p | ...}> or <a,b:t()>
// todo: i, i0 not set unless mentioned? map:{k,v | ..}?
- (AttributeList *) zip_map:(InstanceScope *)aScope exprs:(AMutableArray *)exprs prototype:(ST *)prototype
{
    if (exprs == nil || prototype == nil || [exprs count] == 0) {
        return nil;
    }
    NSInteger i;
    NSInteger cnt;
    NSInteger shorterSize;
    NSInteger numExprs = [exprs count];
    // make everything iterable
    for ( i = 0; i < [exprs count]; i++ ) {
        id attr = [exprs objectAtIndex:i];
        if ( attr != nil )
            [exprs replaceObjectAtIndex:i withObject:[self convertAnythingToIterator:aScope attribute:attr]];
    }
    
    // ensure arguments line up
    CompiledST *code = prototype.impl;
    LinkedHashMap *formalArguments = code.formalArguments;
    if ( !code.hasFormalArgs || formalArguments == nil ) {
        [errMgr runTimeError:self scope:aScope error:MISSING_FORMAL_ARGUMENTS];
        return nil;
    }

    // todo: track formal args not names for efficient filling of locals
    NSArray *formalArgumentNames = [[formalArguments keySet] toArray];
    if ( formalArgumentNames ) [formalArgumentNames retain];
    NSInteger nformalArgs = [formalArgumentNames count];
    if ( [prototype getIsAnonSubtemplate] )
        nformalArgs -= [predefinedAnonSubtemplateAttributes count];
    if ( nformalArgs != numExprs ) {
        [errMgr runTimeError:self
                       scope:aScope
                       error:MAP_ARGUMENT_COUNT_MISMATCH
                         arg:[ACNumber numberWithInteger:numExprs]
                        arg2:[ACNumber numberWithInteger:nformalArgs]];
        // TODO just fill first n
        // truncate arg list to match smaller size
        cnt = [formalArgumentNames count];
        shorterSize = (( cnt < numExprs) ? cnt : numExprs);
        numExprs = shorterSize;
        NSArray *newFormalArgumentNames = [formalArgumentNames subarrayWithRange:NSMakeRange(0,shorterSize)];
        if ( formalArgumentNames ) [formalArgumentNames release];
        formalArgumentNames = newFormalArgumentNames;
        if ( formalArgumentNames ) [formalArgumentNames retain];
    }

    // keep walking while at least one attribute has values

    AttributeList *results = [AttributeList arrayWithCapacity:15];
    i = 0;
    while (YES) {
        NSInteger numEmpty = 0;
        ST *embedded = [group createStringTemplateInternallyWithProto:prototype];
        [embedded rawSetAttribute:@"i0" value:[ACNumber numberWithInteger:i]];
        [embedded rawSetAttribute:@"i"  value:[ACNumber numberWithInteger:i + 1]];
        for (NSInteger a = 0; a < numExprs; a++) {
            ArrayIterator *it = (ArrayIterator *)[exprs objectAtIndex:a];
            [it retain];
            if ( it != nil && [it hasNext] ) {
                NSString *argName = (NSString *)[formalArgumentNames objectAtIndex:a];
                id iteratedValue = [it nextObject];
                [embedded rawSetAttribute:argName value:iteratedValue];
            }
            else {
                numEmpty++;
            }
            [it release];
            it = nil;
        }
        if ( numEmpty == numExprs ) break;
        [results addObject:embedded];
        i++;
    }
    if ( formalArgumentNames ) [formalArgumentNames release];
    return results;
}

- (void) setFirstArgument:(InstanceScope *)aScope st:(ST *)st attr:(id)attr
{
    if ( !st.impl.hasFormalArgs ) {
        if (st.impl.formalArguments == nil) {
            [st add:ST.IMPLICIT_ARG_NAME value:attr];
            return;
        }
        if ( st.impl.formalArguments == nil ) {
            [errMgr runTimeError:self
                       scope:aScope
                       error:ARGUMENT_COUNT_MISMATCH
                         arg:[ACNumber numberWithInteger:1]
                        arg2:(id)st.impl.name
                        arg3:[ACNumber numberWithInteger:0]];
            return;
        }
    }
    if ( [st.locals count] == 0 )
        [st.locals addObject:attr];
    else
        [st.locals replaceObjectAtIndex:0 withObject:attr];
}

- (void) addToList:(InstanceScope *)aScope list:(AMutableArray *)list obj:(id)obj
{
    obj = [self convertAnythingIteratableToIterator:aScope attribute:obj];
    if ([obj isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = (ArrayIterator *)obj;
        [it retain];
        while ([it hasNext]) {
            [list addObject:[it nextObject]];
        }
        [it release];
        it = nil;
    }
    else {
        [list addObject:obj];
    }
}


/**
 * Return the first attribute if multiple valued or the attribute
 * itself if single-valued.  Used in <names:first()>
 */
- (id) first:(InstanceScope *)aScope obj:(id)v
{
    if ( v == nil )
        return v;
    id r = v;
    id tmp;
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = v;
        [it retain];
        if ((tmp = [it nextObject]) != nil) {
            r = tmp;
        }
        [it release];
    }
    return r;
}


/**
 * Return the last attribute if multiple valued or the attribute
 * itself if single-valued. Unless it's a list or array, this is pretty
 * slow as it iterates until the last element.
 */
- (id) last:(InstanceScope *)aScope obj:(id)v
{
    if ( v == nil )
        return v;
    if ([v isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)v;
        return [array objectAtIndex:[array count] - 1];
    }
    else if ([v isKindOfClass:[AMutableArray class]]) {
        AMutableArray *elems = (AMutableArray *)v;
        return [elems objectAtIndex:[elems count]-1];
    }
    id last = v;
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = v;
        [it retain];
        while ([it hasNext]) {
            last = [it nextObject];
        }
        [it release];
        it = nil;
    }
    return last;
}


/**
 * Return everything but the first attribute if multiple valued
 * or null if single-valued.
 */
- (id) rest:(InstanceScope *)aScope obj:(id)v
{
    if ( v == nil )
        return v;
    id obj;
    if ([v isKindOfClass:[NSArray class]]) {
        NSArray *elems = (NSArray *)v;
        if ([elems count] <= 1)
            return nil;
        return [elems subarrayWithRange:NSMakeRange(1, [elems count]-1)];
    }
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = v;
        if ( ![it hasNext] ) {
            return nil; // if not even one value return nil
        }
        [it retain];
        [it nextObject]; // ignore first value
        AMutableArray *a = nil;
        if ( [it hasNext] ) { // Don't bother creating array if your not going to use it
            a = [[AMutableArray arrayWithCapacity:5] retain];
            while ([it hasNext]) {
                obj = [it nextObject];
                [a addObject:obj];
            };
        }
        [it release];
        return a;
    }
    return nil;
}


/**
 * Return all but the last element.  trunc(x)=null if x is single-valued.
 */
- (id) trunc:(InstanceScope *)aScope obj:(id)v
{
    if ( v == nil )
        return v;
    if ( [v isKindOfClass:[NSArray class]] ) {
        NSArray *elems = (NSArray *)v;
        if ( [elems count] <= 1 )
            return nil;
        return [elems subarrayWithRange:NSMakeRange(0, [elems count] - 1)];
    }
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = (ArrayIterator *)v;
        [it retain];
        NSArray *array = [it allObjects];
        [it release];
        NSArray *a = [array subarrayWithRange:NSMakeRange(0, [array count]-1)];
        return a;
    }
    return nil;
}


/**
 * Return a new list w/o null values.
 */
- (id) strip:(InstanceScope *)aScope obj:(id)v
{
    id obj;
    if ( v == nil )
        return v;
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        AMutableArray *a = [[AMutableArray arrayWithCapacity:5] retain];
        ArrayIterator *it = (ArrayIterator *)v;
        [it retain];
        while ((obj = [it nextObject]) != nil) {
            if ( obj != nil && obj != [NSNull null] )
                [a addObject:obj];
        }
        [it release];
        return a;
    }
    return v;
}


/**
 * Return a list with the same elements as v but in reverse order. null
 * values are NOT stripped out. use reverse(strip(v)) to do that.
 */
- (id) reverse:(InstanceScope *)aScope obj:(id)v
{
    if ( v == nil )
        return v;
    v = [self convertAnythingIteratableToIterator:aScope attribute:v];
    if ([v isKindOfClass:[ArrayIterator class]]) {
        AMutableArray *a = [[AMutableArray arrayWithCapacity:5] retain];
        ArrayIterator *it = v;
        [it retain];
        while ([it hasNext]) {
            [a insertObject:[it nextObject] atIndex:0];
        }
        [it release];
        return a;
    }
    return v;
}


/**
 * Return the length of a mult-valued attribute or 1 if it is a
 * single attribute. If attribute is null return 0.
 * Special case several common collections and primitive arrays for
 * speed. This method by Kay Roepke from v3.
 */
- (NSInteger) length:(id)v
{
    if ( v == nil )
        return 0;
    NSInteger i = 1;
    if ( [v isKindOfClass:[HashMap class]] )
        i = [((HashMap *)v) count];
    else if ( [v isKindOfClass:[NSDictionary class]] )
        i = [((NSDictionary *)v) count];
    else if ( [v isKindOfClass:[NSArray class]] )
        i = [((NSArray *)v) count];
    else if ( [v isKindOfClass:[ArrayIterator class]] ) {
        ArrayIterator *it = v;
        [it retain];
        int i = 0;
        while ([it hasNext]) {
            [it nextObject];
            i++;
        }
        [it release];
    }
    return i;
}

- (NSString *) description:(id<STWriter>)wr1 scope:(InstanceScope *)aScope value:(id)value
{
    Class writerClass;
    Writer *stw;
    if ( value != nil ) {
        if ([value isKindOfClass:[ACNumber class]])
            return [value description];
        if ([value isKindOfClass:[NSString class]])
            return (NSString *)value;
//        if ([value isKindOfClass:[ST class]])
//            ((ST *)value).enclosingInstance = aWho;
        StringWriter *sw = [StringWriter newWriter];
        stw = nil;
        @try {
            if ( wr1 == nil ) @throw [IllegalArgumentException newException:@"Writer wr1 is nil"];
            writerClass = [wr1 class];
            stw = [[wr1 class] newWriter:(id<STWriter>)sw];
        }
        @catch (NSException *e) {
            stw = [AutoIndentWriter newWriter:sw];
            [errMgr runTimeError:self
                           scope:aScope
                           error:WRITER_CTOR_ISSUE
                             arg:NSStringFromClass([wr1 class])];
        }
        if (debug && !aScope.earlyEval) {
            aScope = [InstanceScope newInstanceScope:aScope who:aScope.st];
            aScope.earlyEval = YES;
        }
        [self writeObjectNoOptions:stw scope:aScope obj:value];
        return [sw description];
    }
    return nil;
}

- (ArrayIterator *) convertAnythingIteratableToIterator:(InstanceScope *)aScope attribute:(id)obj
{
    ArrayIterator *it = nil;
    if ( obj == nil )
        return nil;
    if ( [obj isKindOfClass:[AMutableArray class]] ) {
        AMutableArray *obj1 = obj;
        it = (ArrayIterator *)[obj1 objectEnumerator];
    }
    else if ( [obj  isKindOfClass:[NSArray class]] )
        it = (ArrayIterator *)[ArrayIterator newIterator:(NSArray *)obj];
    else if ( aScope.st.groupThatCreatedThisInstance.iterateAcrossValues &&
             [obj isKindOfClass:[HashMap class]] )
            it = (ArrayIterator *)[ArrayIterator newIterator:[[(HashMap *)obj values] toArray]];
    else if (  aScope.st.groupThatCreatedThisInstance.iterateAcrossValues &&
             [obj isKindOfClass:[AMutableDictionary class]] )
            it = (ArrayIterator *)[obj objectEnumerator];
    else if ( [obj isKindOfClass:[HashMap class]] )
        it = (ArrayIterator *)[ArrayIterator newIterator:[[(HashMap *)obj keySet] toArray]];
    else if ( [obj isKindOfClass:[AMutableDictionary class]] )
        it = (ArrayIterator *)[obj keyEnumerator];
    else if ( [obj isKindOfClass:[NSDictionary class]] )
        it = (ArrayIterator *)[ArrayIterator newIteratorForDictKey:(NSDictionary *)obj];
    else if ( [obj isKindOfClass:[ArrayIterator class]] )
        it = (ArrayIterator *)obj;
    if ( it == nil )
        return obj;
    [it retain];
    return it;
}

- (ArrayIterator *) convertAnythingToIterator:(InstanceScope *)aScope attribute:(id)obj
{
    obj = [self convertAnythingIteratableToIterator:aScope attribute:obj];
    if ([obj isKindOfClass:[ArrayIterator class]])
        return (ArrayIterator *)obj;
    AttributeList *singleton = [[AttributeList arrayWithCapacity:1] retain];
    [singleton addObject:obj];
    return (ArrayIterator *)[singleton objectEnumerator];
}

- (BOOL) testAttributeTrue:(id)a
{
    if ( a == nil )
        return NO;
    if ( a == (id)YES )
        return YES;
    if ( a < (id)100 )
        return NO;
    if ([a isKindOfClass:[ACNumber class]])
        return [(NSNumber *)a boolValue];
    if ([a isKindOfClass:[NSNumber class]])
        return [(NSNumber *)a boolValue];
    if ([a isKindOfClass:[HashMap class]])
        return ( [((HashMap *)a) count] > 0 );
    if ([a isKindOfClass:[NSArray class]])
        return [((NSArray *)a) count] > 0;
    if ([a isKindOfClass:[NSDictionary class]])
        return [((NSDictionary *)a) count] > 0;
    if ([a isKindOfClass:[ArrayIterator class]]) {
        return [((ArrayIterator *)a) hasNext];
    }
    return YES;
}

- (id) getObjectProperty:(id<STWriter>)anSTWriter scope:(InstanceScope *)aScope obj:(id)obj property:(id)property
{
    if ( obj == nil ) {
        [errMgr runTimeError:self scope:aScope error:NO_SUCH_PROPERTY arg:[NSString stringWithFormat:@"null.%@", property]];
        return nil;
    }
    
    @try {
        id<ModelAdaptor> adap = [aScope.st.groupThatCreatedThisInstance getModelAdaptor:[obj class]];
        return [adap getProperty:self scope:aScope obj:obj property:property propertyName:[self description:anSTWriter scope:aScope value:property]];
    }
    @catch (STNoSuchPropertyException *e) {
        [errMgr runTimeError:self scope:aScope error:NO_SUCH_PROPERTY e:e arg:[NSString stringWithFormat:@"%@.%@", [obj className], property]];
    }
    return nil;
}


/** Find an attr via dynamic scoping up enclosing scope chain.
 *  If not found, look for a map.  So attributes sent in to a template
 *  override dictionary names.
 *
 *  return EMPTY_ATTR if found def but no value
 */
- (id) getAttribute:(InstanceScope *)aScope name:(NSString *)name
{
    InstanceScope *current = aScope;
    while ( current != nil ) {
        FormalArgument *localArg = nil;
        ST *p = current.st;
        if ( p.impl.formalArguments != nil )
            localArg = [p.impl.formalArguments get:name];
        if ( localArg != nil ) {
            id obj = [p.locals objectAtIndex:localArg.index];
            return obj;
        }
        current = current.parent; // look up enclosing scope chain
    }
    
    // got to root scope and no definition, try dictionaries in group and up
    STGroup *g = aScope.st.impl.nativeGroup;
    id obj = [self getDictionary:g name:name];
    if ( obj != nil ) return obj;
    
    // not found, report unknown attr
    if ( ST.cachedNoSuchAttrException == nil ) {
        [ST setCachedNoSuchAttrException:[STNoSuchAttributeException newException:name scope:aScope]];
    }
    STNoSuchAttributeException *nsae = ST.cachedNoSuchAttrException;
    @throw ST.cachedNoSuchAttrException;
}

- (LinkedHashMap *) getDictionary:(STGroup *)g name:(NSString *)name
{
    if ( [g isDictionary:name] ) {
        return [g rawGetDictionary:name];
    }
    if ( g.imports != nil ) {
        for (STGroup *sup in g.imports) {
            id obj = [self getDictionary:sup name:name];
            if ( obj != nil ) return obj;
        }
    }
    return nil;
}

/** Set any default argument values that were not set by the
 *  invoking template or by setAttribute directly.  Note
 *  that the default values may be templates.
 *
 *  The evaluation context is the scope.st template itself so
 *  template default args can see other args.
 */
- (void) setDefaultArguments:(id<STWriter>)wr1 scope:(InstanceScope *)aScope
{
    ST *defaultArgST;
    if ( aScope.st.impl.formalArguments == nil ||
        aScope.st.impl.numberOfArgsWithDefaultValues == 0 )
        return;

    FormalArgument *arg;
    LHMValueIterator *it = [aScope.st.impl.formalArguments newValueIterator];
    while ( [it hasNext] ) {
        arg = (FormalArgument *)[it next];
        // if no value for attribute and default arg, inject default arg into self
        if ( [aScope.st.locals objectAtIndex:arg.index] != ST.EMPTY_ATTR || arg.defaultValueToken == nil ) {
            continue;
        }
        if ( arg.defaultValueToken.type == GroupParser.TANONYMOUS_TEMPLATE ) {
            defaultArgST = [group createStringTemplateInternally:(CompiledST *)arg.compiledDefaultValue];
            defaultArgST.groupThatCreatedThisInstance = group;
            // If default arg is template with single expression
            // wrapped in parens, x={<(...)>}, then eval to string
            // rather than setting x to the template for later
            // eval.
#pragma mark remove debugging print statements
            // NSLog( @"setting def arg %@ to %@", arg.name, defaultArgST );
            NSString *defArgTemplate = arg.defaultValueToken.text;
            if ( [defArgTemplate hasPrefix:[NSString stringWithFormat:@"{%c(", group.delimiterStartChar]] &&
                [defArgTemplate hasSuffix:[NSString stringWithFormat:@")%c}", group.delimiterStopChar]] ) {
                [aScope.st rawSetAttribute:arg.name value:[self description:wr1 scope:aScope value:defaultArgST]];
            }
            else {
                [aScope.st rawSetAttribute:arg.name value:defaultArgST];
            }
        }
        else {
            [aScope.st rawSetAttribute:arg.name value:arg.defaultValue];
        }
    }
    [it release];
}

/** If an instance of x is enclosed in a y which is in a z, return
 *  a String of these instance names in order from topmost to lowest;
 *  here that would be "[z y x]".
 */
- (NSString *)getEnclosingInstanceStackString:(InstanceScope *)aScope
{
    AMutableArray *templates = [Interpreter getEnclosingInstanceStack:aScope topdown:YES];
    NSMutableString *buf = [NSMutableString stringWithCapacity:16];
    int i = 0;
/*
    ArrayIterator *it = [ArrayIterator newIterator:templates];
    ST *st;
    while ( [it hasNext] ) {
        st = (ST *)[it nextObject];
 */
    for (ST *st in templates) {
        if ( i > 0 ) [buf appendString:@" "];
        [buf appendString:[st getName]];
        i++;
    }
    return buf;
}

+ (AMutableArray *)getEnclosingInstanceStack:(InstanceScope *)scope topdown:(BOOL)topdown
{
    AMutableArray *stack = [AMutableArray arrayWithCapacity:5];
    InstanceScope *p = scope;
    while ( p != nil ) {
        if ( topdown ) [stack insertObject:p.st atIndex:0];
        else [stack addObject:p.st];
        p = p.parent;
    }
    return stack;
}

+ (AMutableArray *) getScopeStack:(InstanceScope *)scope direction:(BOOL)topdown
{
    AMutableArray *stack = [AMutableArray arrayWithCapacity:10];
    InstanceScope *p = scope;
    while ( p != nil ) {
        if ( topdown ) [stack insertObject:p atIndex:0];
        else [stack addObject:p];
        p = p.parent;
    }
    return stack;
}

+ (AMutableArray *) getEvalTemplateEventStack:(InstanceScope *)scope direction:(BOOL)topdown
{
    AMutableArray *stack = [AMutableArray arrayWithCapacity:10];
    InstanceScope *p = scope;
    while ( scope != nil ) {
        EvalTemplateEvent *eval = [p.events objectAtIndex:[p.events count]-1];
        if ( topdown ) [stack insertObject:eval atIndex:0];
        else [stack addObject:eval];
        p = p.parent;
    }
    return stack;
}

- (void) trace:(InstanceScope *)aScope ip:(NSInteger)ip
{
    NSMutableString *tr = [NSMutableString stringWithCapacity:16];
    BytecodeDisassembler *dis = [BytecodeDisassembler newBytecodeDisassembler:aScope.st.impl];
    NSMutableString *buf = [NSMutableString stringWithCapacity:16];
    [dis disassembleInstruction:buf ip:ip];
    NSString *name = [NSString stringWithFormat:@"%@:", aScope.st.impl.name];
    if (aScope.st.impl.name == ST.UNKNOWN_NAME)
        name = @"";
    [tr appendString:[NSMutableString stringWithFormat:@"%-40@%@\tstack=[", name, buf]];
    
    for (NSInteger i = 0; i <= sp; i++) {
        id obj = operands[i];
        [self printForTrace:tr scope:aScope obj:obj];
    }
    
    [tr appendFormat:@" ], calls=%@, sp=%ld, nw=%ld", [self getEnclosingInstanceStackString:aScope], (long)sp, (long)nwline];
    NSString *s = [NSString stringWithString:tr];
    if (debug)
        [executeTrace addObject:s];
    if (trace) {
        NSLog(@"%@", s );
    }
}

- (void) printForTrace:(NSMutableString *)tr scope:(InstanceScope *)aScope obj:(id)obj
{
    if ([obj isKindOfClass:[ST class]]) {
        if (((ST *)obj).impl == nil)
            [tr appendString:@"bad-template()"];
        else
            [tr appendFormat:@" %@()", ((ST *)obj).impl.name];
        return;
    }
    obj = [self convertAnythingIteratableToIterator:aScope attribute:obj];
    if ([obj isKindOfClass:[ArrayIterator class]]) {
        ArrayIterator *it = (ArrayIterator *)obj;
        [it retain];
        [tr appendString:@" ["];
        while ([it hasNext]) {
            id iterValue = [it nextObject];
            [self printForTrace:tr scope:aScope obj:iterValue];
        }
        [it release];
        [tr appendString:@" ]"];
    }
    else {
        [tr appendFormat:@" %@", obj];
    }
}

- (AMutableArray *) getEvents
{
    return events;
}

/** For every event, we track in overall list and in self's
 *  event list so that each template has a list of events used to
 *  create it.  If EvalTemplateEvent, store in parent's
 *  childEvalTemplateEvents list for STViz tree view.
 */
- (void) trackDebugEvent:(InstanceScope *)aScope event:(InterpEvent *)e
{
//  System.out.println(e);
    [self.events addObject:e];
    [aScope.events addObject:e];
    if ( [e isKindOfClass:[EvalTemplateEvent class]] ) {
        InstanceScope *parent = aScope.parent;
        if ( parent != nil ) {
            // System.out.println("add eval "+e.self.getName()+" to children of "+parent.getName());
            [aScope.parent.childEvalTemplateEvents addObject:(EvalTemplateEvent *)e];
        }
    }
}

- (AMutableArray *) getExecutionTrace
{
    return executeTrace;
}


+ (NSInteger) getShort:(char *)memory index:(NSInteger)index
{
    NSInteger b1 = memory[index] & 0xFF;
    NSInteger b2 = memory[index + 1] & 0xFF;
    return b1 << (8 * 1) | b2;
}

@end
