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
#import <ANTLR/LinkedHashMap.h>
#import "STErrorListener.h"
#import "ST.h"
#import "STGroup.h"
#import "STGroupDir.h"
#import "STGroupFile.h"
#import "Bytecode.h"
#import "BytecodeDisassembler.h"
#import "CompilationState.h"
#import "CompiledST.h"
#import "Compiler.h"
#import "FormalArgument.h"
#import "STException.h"
#import "Compiler.h"
//#import "DebugST.h"
#import "Coordinate.h"
#import "ErrorBuffer.h"
#import "ErrorManager.h"
#import "ErrorType.h"
#import "Interval.h"
#import "Misc.h"
#import "STCompiletimeMessage.h"
//#import "STDump.h"
#import "STGroupCompiletimeMessage.h"
#import "STLexerMessage.h"
#import "STMessage.h"
#import "STRuntimeMessage.h"
#import "ModelAdaptor.h"
#import "MapModelAdaptor.h"
#import "STModelAdaptor.h"
#import "AggregateModelAdaptor.h"
#import "DictModelAdaptor.h"
#import "ObjectModelAdaptor.h"
#import "GroupLexer.h"
#import "GroupParser.h"

@implementation STGroup_Anon1

@synthesize dict;

+ (id) newSTGroup_Anon1
{
    return [[STGroup_Anon1 alloc] init];
}

- (id) init
{
    self=[super init];
    if ( self != nil ) {
        dict = [[LinkedHashMap newLinkedHashMap:16] retain];
        [dict put:[NSObject className] value:[ObjectModelAdaptor newModelAdaptor]];
        [dict put:[ST className] value:[STModelAdaptor newModelAdaptor]];
        [dict put:[HashMap className] value:[MapModelAdaptor newModelAdaptor]];
        [dict put:[NSDictionary className] value:[DictModelAdaptor newModelAdaptor]];
        [dict put:[Aggregate className] value:[AggregateModelAdaptor newModelAdaptor]];
    }
    return self;
}

- (void) dealloc
{
#ifdef DEBUG_DEALLOC
    NSLog( @"called dealloc in STGroup_Anon1" );
#endif
    if ( dict ) [dict release];
    [super dealloc];
}

- (id) getDict
{
    return dict;
}

- (id) get:(id)aKey
{
    //    return [dict objectForKey:aKey];
    return [dict get:aKey];
}

- (void) put:(id)aKey value:(id)anObject
{
    //    [dict setObject:anObject forKey:aKey];
    [dict put:aKey value:anObject];
}

- (NSInteger) count
{
    return [dict count];
}

@end

/** A directory or directory tree of .st template files and/or group files.
 *  Individual template files contain formal template definitions. In a sense,
 *  it's like a single group file broken into multiple files, one for each template.
 *  ST v3 had just the pure template inside, not the template name and header.
 *  Name inside must match filename (minus suffix).
 */
@implementation STGroup

/**
 * Used to indicate that the template doesn't exist.
 * Prevents duplicate group file loads and unnecessary file checks.
 */
static STGroup      *aDefaultGroup = nil;
// static CompiledST   *NOT_FOUND_ST = nil;
/**
 * When we use key as a value in a dictionary, this is how we signify.
 */
static const NSString *DICT_KEY = @"key";
static const NSString *DEFAULT_KEY = @"default";
static BOOL debug = NO;
static BOOL verbose = YES;
static BOOL trackCreationEvents = NO;

@synthesize encoding; 
@synthesize imports;
@synthesize importsToClearOnUnload;
@synthesize delimiterStartChar;
@synthesize delimiterStopChar;
@synthesize templates;
@synthesize dictionaries;
@synthesize renderers;
@synthesize adaptors;
@synthesize errMgr;
@synthesize typeToAdaptorCache;
@synthesize typeToRendererCache;
@synthesize iterateAcrossValues;

+ (void) initialize
{
    aDefaultGroup = [[STGroup newSTGroup] retain];
}
/*
+ (CompiledST *) NOT_FOUND_ST
{
    if (NOT_FOUND_ST == nil)
        NOT_FOUND_ST = [[CompiledST newCompiledST] retain];
    return NOT_FOUND_ST;
}
*/

+ (NSString *) DEFAULT_KEY
{
    return DEFAULT_KEY;
}

+ (NSString *) DICT_KEY
{
    return DICT_KEY;
}

+ (STGroup *) defaultGroup
{
    if (aDefaultGroup == nil)
        aDefaultGroup = [[STGroup newSTGroup] retain];
    return aDefaultGroup;
}

+ (void) resetDefaultGroup
{
    if ( aDefaultGroup ) [aDefaultGroup release];
    aDefaultGroup = nil;
}

+ (BOOL)trackCreationEvents
{
    return trackCreationEvents;
}

+ (BOOL) debug
{
    return debug;
}

+ (void) setDebug
{
    debug = YES;
}

+ (BOOL) verbose
{
    return verbose;
}

+ (void) setVerbose
{
    verbose = YES;
}

+ (id) newSTGroup
{
    return [[STGroup alloc] init:(unichar)'<' delimiterStopChar:(unichar)'>'];
}

+ (id) newSTGroup:(unichar)startChar delimiterStopChar:(unichar)stopChar
{
    return [[STGroup alloc] init:startChar delimiterStopChar:stopChar];
}

- (id) init:(unichar)aDelimiterStartChar delimiterStopChar:(unichar)aDelimiterStopChar
{
    self=[super init];
    if ( self != nil ) {
        encoding = NSUTF8StringEncoding;
        delimiterStartChar = aDelimiterStartChar;
        delimiterStopChar = aDelimiterStopChar;
        imports = [[AMutableArray arrayWithCapacity:16] retain];
        importsToClearOnUnload = [[AMutableArray arrayWithCapacity:16] retain];
        templates = [[LinkedHashMap newLinkedHashMap:16] retain];
        dictionaries = [[LinkedHashMap newLinkedHashMap:16] retain];
        adaptors = [[[STGroup_Anon1 newSTGroup_Anon1] getDict] retain];
        typeToAdaptorCache = [[LinkedHashMap newLinkedHashMap:16] retain];
        iterateAcrossValues = NO;
        errMgr = ErrorManager.DEFAULT_ERR_MGR;
        [errMgr retain];
    }
    return self;
}

- (void)dealloc
{
#ifdef DEBUG_DEALLOC
    NSLog( @"called dealloc in STGroup" );
#endif
    if ( imports ) [imports release];
    if ( importsToClearOnUnload ) [importsToClearOnUnload release];
    if ( templates ) [templates release];
    if ( dictionaries ) [dictionaries release];
    if ( renderers ) [renderers release];
    if ( adaptors ) [adaptors release];
    if ( typeToAdaptorCache ) [typeToAdaptorCache release];
    if ( typeToRendererCache ) [typeToRendererCache release];
    if ( errMgr ) [errMgr release];
    [super dealloc];
    if (self == aDefaultGroup) aDefaultGroup = nil;
}


/** The primary means of getting an instance of a template from this
 *  group. Names must be absolute, fully-qualified names like a/b
 */
- (ST *) getInstanceOf:(NSString *)aName
{
    if ( aName == nil ) return nil;
    if ( verbose ) NSLog(@"[%@ getInstanceOf:%@]\n", [self className], aName);
    if ( [aName characterAtIndex:0] != '/') aName = [NSString stringWithFormat:@"/%@", aName];
    CompiledST *c = [self lookupTemplate:aName];
    if ( c != nil ) {
        return [self createStringTemplate:c];
    }
    return nil;
}

- (ST *) getEmbeddedInstanceOf:(Interpreter *)interp
                           who:(ST *)enclosingInstance
                            ip:(NSInteger)ip
                          name:(NSString *)aName
{
    NSString *fullyQualifiedName = aName;
    if ( [aName characterAtIndex:0] != '/' ) {
        fullyQualifiedName = [NSString stringWithFormat:@"%@%@", enclosingInstance.impl.prefix, aName];
    }
    if ( verbose ) NSLog( @"[self getEmbeddedInstanceOf:%@]\n", fullyQualifiedName);
    ST *st = [self getInstanceOf:fullyQualifiedName];
    if ( st == nil ) {
        [errMgr runTimeError:interp who:enclosingInstance
                          ip:ip
                       error:NO_SUCH_TEMPLATE
                         arg:fullyQualifiedName];
        return [self createStringTemplateInternally:[CompiledST newCompiledST]];
    }
    // this is only called internally. whack any debug ST create events
    if ( trackCreationEvents ) {
        st.debugState.newSTEvent = nil; // toss it out
    }
    return st;
}

/** Create singleton template for use with dictionary values */
- (ST *) createSingleton:(CommonToken *)templateToken
{
    NSString *template;
    if ( templateToken.type == GroupParser.TBIGSTRING ) {
        template = [Misc strip:templateToken.text n:2];
    }
    else {
        template = [Misc strip:templateToken.text n:1];
    }
    CompiledST *impl = [[self compile:[self getFileName] name:nil args:nil template:template templateToken:templateToken] retain];
    ST *st = [self createStringTemplateInternally:impl];
    st.groupThatCreatedThisInstance = self;
    st.impl.hasFormalArgs = NO;
    st.impl.name = ST.UNKNOWN_NAME;
    [st.impl defineImplicitlyDefinedTemplates:self];
    return st;
}

/** Is this template defined in this group or from this group below?
 *  Names must be absolute, fully-qualified names like /a/b
 */
- (BOOL) isDefined:(NSString *)aName
{
    return ([self lookupTemplate:aName] != nil);
}

/** Look up a fully-qualified name */
- (CompiledST *) lookupTemplate:(NSString *)aName
{
    if ( [aName characterAtIndex:0] != '/') aName = [NSString stringWithFormat:@"/%@", aName];
    if ( verbose ) NSLog(@"[%@ lookupTemplate:%@]\n", [self className], aName);
    CompiledST *code = [self rawGetTemplate:aName];
    if ( code == CompiledST.NOT_FOUND_ST ) {
        if ( verbose ) NSLog(@"%@ previously seen as not found\n", aName);
        return nil;
    }
    // try to load from disk and look up again
    if ( code == nil ) code = [self load:aName];
    if ( code == nil ) code = [self lookupImportedTemplate:aName];
    if ( code == nil ) {
        if ( verbose ) NSLog(@"%@ recorded not found\n", aName);
        [templates put:aName value:CompiledST.NOT_FOUND_ST];
    }
    if ( verbose && code != nil ) NSLog(@"[%@ lookupTemplate:%@] found\n", [self className], aName);
    return code;
}

/** "unload" all templates, dictionaries and import relationships, but leave
 *  renderers and adaptors.  This essentially forces next getInstanceOf
 *  to reload templates. Call unload() on each group in the imports list
 *  and remove every import from the imports list imported with
 *  "clearOnUnload".
 */
- (void) unload
{
    [templates clear];
    [dictionaries clear];
    STGroup *imp;
    for ( imp in imports ) {
        [imp unload];
    }
    if ( [imports count] > 0) [imports removeAllObjects];
    if ( [importsToClearOnUnload count] > 0) [importsToClearOnUnload removeAllObjects];
}

/** Load st from disk if dir or load whole group file if .stg file (then
 *  return just one template). name is fully-qualified.
 */
- (CompiledST *) load:(NSString *)name
{
    return nil;
}


/**
 * Force a load if it makes sense for the group
 */
- (void) load
{
    return;
}

- (CompiledST *) lookupImportedTemplate:(NSString *)aName
{
    if ( imports == nil || [imports count] == 0)
        return nil;
    STGroup *g;
    for ( g in imports ) {
        if ( verbose ) NSLog(@"checking %@  for imported %@\n", [g getName], aName);
        CompiledST *code = [g lookupTemplate:aName];
        if ( code != nil ) {
            if ( verbose ) NSLog(@"[%@ lookupImportedTemplate:%@] found\n", [g getName], aName);
            return code;
        }
    }
    if ( verbose ) NSLog(@"%@ not found in %@ imports\n", aName, [self getName]);
    return nil;
}

- (CompiledST *) rawGetTemplate:(NSString *)aName
{
    CompiledST *c = [templates get:aName];
    return c;
}

- (LinkedHashMap *) rawGetDictionary:(NSString *)aName
{
    return [dictionaries get:aName];
}

- (BOOL) isDictionary:(NSString *)aName
{
    return ([dictionaries get:aName] != nil);
}

// for testing
- (CompiledST *) defineTemplate:(NSString *)templateName template:(NSString *)aTemplate
{
    if ( [templateName characterAtIndex:0] != '/')
        templateName = [NSString stringWithFormat:@"/%@", templateName];
    @try {
        CompiledST *impl = [self defineTemplate:templateName
                                          nameT:[CommonToken newToken:GroupParser.TID Text:templateName]
                                           args:nil
                                       template:aTemplate
                                  templateToken:nil];
        return impl;
    }
    @catch (STException *se) {
        // we have reported the error; the exception just blasts us
        // out of parsing this template
    }
    return nil;
}

// for testing
- (CompiledST *) defineTemplate:(NSString *)aName argsS:(NSString *)argsS template:(NSString *)template
{
    if ( [aName characterAtIndex:0] != '/' ) aName = [NSString stringWithFormat:@"/%@", aName];
    __strong NSArray *args = [[argsS componentsSeparatedByString:@","] retain];
    __strong AMutableArray *a = [[AMutableArray arrayWithCapacity:5] retain];

    NSString *arg;
    for ( arg in args ) {
        [a addObject:[FormalArgument newFormalArgument:arg]];
    }
    return [self defineTemplate:aName
                          nameT:[CommonToken newToken:GroupParser.TID Text:aName]
                           args:a
                       template:template
                  templateToken:nil];
}

- (CompiledST *) defineTemplate:(NSString *)fullyQualifiedTemplateName
                          nameT:(CommonToken *)nameT
                           args:(AMutableArray *)args
                       template:(NSString *)template
                  templateToken:(CommonToken *)templateToken
{
    if ( verbose )
        NSLog(@"[%@ defineTemplate:%@]\n", [self className], fullyQualifiedTemplateName);
    if (fullyQualifiedTemplateName == nil || [fullyQualifiedTemplateName length] == 0) {
        @throw [IllegalArgumentException newException:@"empty template name"];
    }
    NSInteger i;
    for (i = ([fullyQualifiedTemplateName length]-1); i >= 0; i-- ) {
        if ( [fullyQualifiedTemplateName characterAtIndex:i] == '.' ) break;
    }
    if (i >= 0) {
        @throw [IllegalArgumentException newException:@"cannot have '.' in template names"];
    }
    template = [Misc trimOneStartingNewline:template];
    template = [Misc trimOneTrailingNewline:template];
    CompiledST *code = [[self compile:[self getFileName] name:fullyQualifiedTemplateName args:args template:template templateToken:templateToken] retain];
    code.name = [fullyQualifiedTemplateName retain];
    [self rawDefineTemplate:fullyQualifiedTemplateName code:code defT:nameT];
    [code defineArgDefaultValueTemplates:self];
    [code defineImplicitlyDefinedTemplates:self]; // define any anonymous subtemplates

    return code;
}

/** Make name and alias for target.  Replace any previous def of name */
- (CompiledST *) defineTemplateAlias:(CommonToken *)aliasT targetT:(CommonToken *)targetT
{
    NSString *alias = aliasT.text;
    NSString *target = targetT.text;
    CompiledST *targetCode = [self rawGetTemplate:[NSString stringWithFormat:@"/%@", target]];
    if ( targetCode == nil ) {
        [errMgr compileTimeError:ALIAS_TARGET_UNDEFINED templateToken:nil t:aliasT arg:alias arg2:target];
        return nil;
    }
    [self rawDefineTemplate:[NSString stringWithFormat:@"/%@", alias] code:targetCode defT:aliasT];
    return targetCode;
}

- (CompiledST *) defineRegion:(NSString *)enclosingTemplateName
                      regionT:(CommonToken *)regionT
                     template:(NSString *)template
                templateToken:(CommonToken *)templateToken
{
    NSString *aName = regionT.text;
    template = [Misc trimOneStartingNewline:template];
    template = [Misc trimOneTrailingNewline:template];
    CompiledST *code = [self compile:[self getFileName] name:enclosingTemplateName args:nil template:template templateToken:templateToken];
    NSString *mangled = [STGroup getMangledRegionName:enclosingTemplateName name:aName];
    if ( [self lookupTemplate:mangled] == nil ) {
        [errMgr compileTimeError:NO_SUCH_REGION templateToken:templateToken t:regionT arg:enclosingTemplateName arg2:aName];
        return [CompiledST newCompiledST];
    }
    code.name = mangled;
    code.isRegion = YES;
    code.regionDefType = EXPLICIT; /* ST.RegionType.EXPLICIT */
    code.templateDefStartToken = regionT;
    [self rawDefineTemplate:mangled code:code defT:regionT];
    [code defineArgDefaultValueTemplates:self];
    [code defineImplicitlyDefinedTemplates:self];

    return code;
}

- (void) defineTemplateOrRegion:(NSString *)fullyQualifiedTemplateName
  regionSurroundingTemplateName:(NSString *)regionSurroundingTemplateName
                  templateToken:(CommonToken *)templateToken
                       template:(NSString *)template
                      nameToken:(CommonToken *)nameToken
                           args:(AMutableArray *)args
{
    @try {
        if ( regionSurroundingTemplateName != nil ) {
            [self defineRegion:regionSurroundingTemplateName regionT:nameToken template:template templateToken:templateToken];
        }
        else {
            [self defineTemplate:fullyQualifiedTemplateName nameT:nameToken args:args template:template templateToken:templateToken];
        }
    }
    @catch (STException *e) {
        // after getting syntax error in a template, we emit msg
        // and throw exception to blast all the way out here.
    }
}

- (void) rawDefineTemplate:(NSString *)aName code:(CompiledST *)code defT:(CommonToken *)defT
{
    CompiledST *prev = [self rawGetTemplate:aName];
    if ( prev != nil ) {
        if ( !prev.isRegion ) {
            [errMgr compileTimeError:TEMPLATE_REDEFINITION templateToken:nil t:defT];
            return;
        }
        if ( prev.isRegion ) {
            if ( code.regionDefType != IMPLICIT &&
                 prev.regionDefType == EMBEDDED ) {
                [errMgr compileTimeError:EMBEDDED_REGION_REDEFINITION templateToken:nil t:defT arg:[STGroup getUnMangledTemplateName:aName]];
                return;
            }
            else if ( code.regionDefType == IMPLICIT ||
                      prev.regionDefType == EXPLICIT ) {
                [errMgr compileTimeError:REGION_REDEFINITION templateToken:nil t:defT arg:[STGroup getUnMangledTemplateName:aName]];
                return;
            }
        }
    }
    code.nativeGroup = self;
    code.templateDefStartToken = defT;
    [templates put:aName value:code];
}
    
- (void) undefineTemplate:(NSString *)aName
{
    [templates remove:aName];
}
    
/** Compile a template */
- (CompiledST *) compile:(NSString *)srcName
                    name:(NSString *)aName
                    args:(AMutableArray *)args
                template:(NSString *)aTemplate
           templateToken:(CommonToken *)aTemplateToken
{
    // if ( verbose ) NSLog(@"STGroup.compile: %@\n", enclosingTemplateName);
    Compiler *c = [Compiler newCompiler:self];
    CompiledST *code = [c compile:srcName name:aName args:args template:aTemplate templateToken:aTemplateToken];
    if ( code ) [code retain];
    return code;
}

/** The "foo" of t() ::= "<@foo()>" is mangled to "region#t#foo" */
+ (NSString *) getMangledRegionName:(NSString *)anEnclosingTemplateName name:(NSString *)aName
{
    if ( [anEnclosingTemplateName characterAtIndex:0] != '/' )
        anEnclosingTemplateName = [NSString stringWithFormat:@"/%@", anEnclosingTemplateName];
    NSString *tmp = [NSString stringWithFormat:@"region__%@__%@", anEnclosingTemplateName, aName];
    return tmp;
}


/** Return "t.foo" from "region__t__foo" */
+ (NSString *) getUnMangledTemplateName:(NSString *)mangledName
{
    NSInteger len = [@"region__" length];
    NSRange r1 = [mangledName rangeOfString:@"__" options:NSBackwardsSearch];
    NSRange r2 = NSMakeRange(len, r1.location-len);
    NSString *t = [mangledName substringWithRange:r2];
    NSString *r = [mangledName substringWithRange:NSMakeRange(r1.location+2, [mangledName length]-(r1.location+2))];
    NSString *tmp = [NSString stringWithFormat:@"%@.%@", t, r];
    return tmp;
}

/** Define a map for this group; not thread safe...do not keep adding
 *  these while you reference them.
 */
- (void) defineDictionary:(NSString *)aName mapping:(LinkedHashMap *)mapping
{
    [dictionaries put:aName value:mapping];
}

- (void) importTemplates:(STGroup *)g
{
    [self importTemplates:g ClearOnUnload:NO];
}

/** Import template files, directories, and group files.
 *   Priority is given to templates defined in the current group;
 *   this, in effect, provides inheritance. Polymorphism is in effect so
 *   that if an inherited template references template t() then we
 *   search for t() in the subgroup first.
 *
 *   If you specify an absolute file name or directory name, the
 *   import statement uses that directly. If it is not an absolute path,
 *   we look that entity up in the directory holding the group that
 *   initiates the import. If file or directory is not in that directory,
 *   then we load using the classpath.
 *
 *   Templates are loaded on-demand from import dirs.  Imported groups are
 *   loaded on-demand when searching for a template.
 *
 *   The listener of this group is passed to the import group so errors
 *   found while loading imported element are sent to listener of this group.
 */
- (void) importTemplatesWithFileName:(CommonToken *)fileNameToken
{
    if (verbose) NSLog(@"[self importTemplates:%@]\n", fileNameToken.text);
    NSString *aFileName = fileNameToken.text;
    // do nothing upon syntax error
    if ( aFileName == nil || [aFileName isEqualToString:@"<missing STRING>"] )
        return;
    aFileName = [Misc strip:aFileName n:1];
    
    //NSLog(@"import %@", aFileName);
    BOOL isGroupFile = [aFileName hasSuffix:@".stg"];
    BOOL isTemplateFile = [aFileName hasSuffix:@".st"];
    BOOL isGroupDir = !(isGroupFile || isTemplateFile);
    
    STGroup *g = nil;

    // it's a relative name; search path is working dir, g.stg's dir, CLASSPATH
    NSString *rootPath = [[self getRootDirURL] path];
    NSString *fileUnderRoot = [[self getRootDirURL] path];
    if ( [fileUnderRoot hasSuffix:@".stg"] ) {
        fileUnderRoot = [Misc getParent:fileUnderRoot];
    }
    fileUnderRoot = [fileUnderRoot stringByAppendingPathComponent:aFileName];
    fileUnderRoot = [fileUnderRoot stringByStandardizingPath];
    NSURL *fileURL = [NSURL fileURLWithPath:fileUnderRoot];

    if ( isTemplateFile ) {
        g = [STGroup newSTGroup];
        [g setListener:[self getListener]];
        ANTLRInputStream *templateStream = nil;
        @try {
            if ( ![Misc urlExists:fileURL] ) {
                IOException *ioe = [IOException newException:[NSString stringWithFormat:@"File Not Found %@\n", fileURL]];
                @throw ioe;
            }
            NSInputStream *is = [NSInputStream inputStreamWithURL:fileURL];
            templateStream = [ANTLRInputStream newANTLRInputStream:is];
            templateStream.name = aFileName;
            CompiledST *code = [g loadTemplateFile:@"/" fileName:aFileName stream:templateStream];
            if ( code==nil ) g = nil;
        }
        @catch (MalformedURLException *mfe) {
            [errMgr internalError:nil msg:[NSString stringWithFormat:@"can't build URL for %@\n", fileUnderRoot] e:mfe];
        }
        @catch (IOException *ioe) {
            // not found
            [errMgr internalError:nil msg:[NSString stringWithFormat: @"can't read from %@\n", fileURL] e:ioe];
            g = nil;
        }
    }
    else if ( isGroupFile ) {
//      NSLog(@"look for fileUnderRoot: %@", fileUnderRoot);
        if ( [Misc urlExists:fileURL] ) {
            g = [STGroupFile newSTGroupFile:fileUnderRoot encoding:encoding delimiterStartChar:delimiterStartChar delimiterStopChar:delimiterStopChar];
            [g setListener:[self getListener]];
        }
        else {
            g = [STGroupFile newSTGroupFile:aFileName delimiterStartChar:delimiterStartChar delimiterStopChar:delimiterStopChar];
            [g setListener:[self getListener]];
        }
    }
    else if ( isGroupDir ) {
//      NSLog(@"try dir %@", fileUnderRoot);
        if ( [Misc urlExists:fileURL] ) {
            g = [STGroupFile newSTGroupFile:fileUnderRoot encoding:encoding delimiterStartChar:delimiterStartChar delimiterStopChar:delimiterStopChar];
            [g setListener:[self getListener]];
        }
        else {
            g = [STGroupFile newSTGroupFile:aFileName delimiterStartChar:delimiterStartChar delimiterStopChar:delimiterStopChar];
            [g setListener:[self getListener]];
        }
    }
    
    if ( g == nil ) {
        [errMgr compileTimeError:CANT_IMPORT templateToken:nil t:fileNameToken arg:aFileName];
    }
    else {
        [self importTemplates:g];
    }
}

- (void) importTemplates:(STGroup *)g ClearOnUnload:(BOOL)clearOnUnload
{
    if ( g == nil ) return;
    [imports addObject:g];
    if (clearOnUnload) {
        [importsToClearOnUnload addObject:g];
    }
    
}

- (AMutableArray *) getImportedGroups
{
    return imports;
}

/** Load a group file with full path fileName; it's relative to root by prefix. */
- (void) loadGroupFile:(NSString *)prefix fileName:(NSString *)aFileName
{
    if ( verbose )
        NSLog(@"[%@.loadGroupFile:%@ fileName:%@]\n",
              [NSString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding],
              prefix, aFileName);
    GroupParser *aParser = nil;
    @try {
        NSString *fn = [aFileName stringByStandardizingPath];
        NSURL *f = [NSURL fileURLWithPath:fn];
        if ( ![Misc urlExists:f] ) {
            NSException *e = [NSException exceptionWithName:@"LOADGroupError" reason:@"Can't load group file" userInfo:nil];
            @throw e;
        }
        NSInputStream *is = [NSInputStream inputStreamWithURL:f];
        ANTLRInputStream *ais = [ANTLRInputStream newANTLRInputStream:is];
        ais.name = aFileName;
        GroupLexer *lexer = [GroupLexer newGroupLexerWithCharStream:ais];
        CommonTokenStream *tokens = [CommonTokenStream newCommonTokenStreamWithTokenSource:lexer];
        aParser = [GroupParser newGroupParser:tokens];
        [aParser group:self prefix:prefix];
    }
    @catch (NSException *e) {
        [errMgr IOError:nil error:CANT_LOAD_GROUP_FILE e:e arg:aFileName];
    }
}

/** Load template file into this group using absolute filename */
- (CompiledST *) loadAbsoluteTemplateFile:(NSString *) aFileName
{
    ANTLRFileStream *afs;
    @try {
        if ( ![Misc urlExists:[NSURL URLWithString:aFileName]] ) {
            @throw [IOException newException:[NSString stringWithFormat:@"file %@ doesn't exist", aFileName]];
        }
        afs = [ANTLRFileStream newANTLRFileStream:aFileName encoding:NSASCIIStringEncoding];
        afs.name = aFileName;
    }
    @catch (IOException *ioe) {
        // doesn't exist
        //errMgr.IOError(null, ErrorType.NO_SUCH_TEMPLATE, ioe, fileName);
        return nil;
    }
    return [self loadTemplateFile:@"" fileName:aFileName stream:afs];
}

/** Load template stream into this group. unqualifiedFileName is "a.st".
 *  The prefix is path from group root to unqualifiedFileName like /subdir
 *  if file is in /subdir/a.st
 */
- (CompiledST *) loadTemplateFile:(NSString *)prefix fileName:(NSString *)aFileName stream:(id<CharStream>)templateStream
{
    GroupLexer *lexer = [GroupLexer newGroupLexerWithCharStream:templateStream];
    CommonTokenStream *tokens = [CommonTokenStream newCommonTokenStreamWithTokenSource:lexer];
    GroupParser *parser = [GroupParser newGroupParser:tokens];
    parser.group = self;
    lexer.group = self;
    @try {
        [parser templateDef:prefix];
    }
    @catch (RecognitionException *re) {
        [errMgr groupSyntaxError:SYNTAX_ERROR srcName:aFileName e:re msg:[re getMessage]];
    }
    NSString *templateName = [Misc getFileNameNoSuffix:aFileName];
    if ( prefix != nil && [prefix length] > 0 )
        templateName = [NSString stringWithFormat:@"%@%@", prefix, templateName];
    CompiledST *impl = [self rawGetTemplate:templateName];
    impl.prefix = prefix;
    return impl;
}

/** Add an adaptor for a kind of object so ST knows how to pull properties
 *  from them. Add adaptors in increasing order of specificity.  ST adds Object,
 *  Map, and ST model adaptors for you first. Adaptors you add have
 *  priority over default adaptors.
 * 
 *  If an adaptor for type T already exists, it is replaced by the adaptor arg.
 * 
 *  This must invalidate cache entries, so set your adaptors up before
 *  render()ing your templates for efficiency.
 */
- (void) registerModelAdaptor:(Class)attributeType adaptor:(id<ModelAdaptor>)adaptor
{
    //class_getName(Class cls)
    if ( attributeType == nil ) {
        @throw [IllegalArgumentException newException:
                [NSString stringWithFormat:@"can't register ModelAdaptor for primitive type %@",
                 NSStringFromClass(attributeType)]];
    }
    [adaptors put:NSStringFromClass(attributeType) value:adaptor];
    [self invalidateModelAdaptorCache:attributeType];
}

/** remove at least all types in cache that are subclasses or implement attributeType */
- (void) invalidateModelAdaptorCache:(Class)attributeType
{
    [typeToAdaptorCache clear]; // be safe, not clever; whack all values
}

- (id<ModelAdaptor>) getModelAdaptor:(Class)attributeType
{
    id<ModelAdaptor> a = [typeToAdaptorCache get:NSStringFromClass(attributeType)];
    if ( a != nil )
        return a;

    //System.out.println("looking for adaptor for "+attributeType);
    // Else, we must find adaptor that fits;
    // find last fit (most specific)
    NSString *t;
//    for ( t in [adaptors keyEnumerator] ) {
    NSString *tmp;
    LHMKeyIterator *it = [adaptors newKeyIterator];
    while ( [it hasNext] ) {
        // t works for attributeType if attributeType subclasses t or implements
        t = (NSString *)[it next];
        Class cls = objc_getClass([t UTF8String]);
        if ([attributeType isSubclassOfClass:cls]) {
            a = [adaptors get:t];
        }
    }
    [typeToAdaptorCache put:NSStringFromClass(attributeType) value:a];
    return a;
}


/** Register a renderer for all objects of a particular "kind" for all
 *  templates evaluated relative to this group.  Use r to render if
 *  object in question is instanceof(attributeType).
 */
- (void) registerRenderer:(id)attributeType r:(id<AttributeRenderer>)r
{
    [self registerRenderer:attributeType r:r recurs:YES];
}

- (void) registerRenderer:(Class)attributeType r:(id<AttributeRenderer>)r recurs:(BOOL)recursive
{
    /*
     if ( attributeType.isPrimitive() ) {
        @throw [IllegalArgumentException newException:
            [NSString stringWithFormat:@"can't register ModelAdaptor for primitive type %@",
            [attributeType getSimpleName]];
     }
//     [typeToAdaptorCache removeAllObjects]; // be safe, not clever; whack all values
     [typeToAdaptorCache clear]; // be safe, not clever; whack all values
     */
    if (renderers == nil) {
        renderers = [[LinkedHashMap newLinkedHashMap:5] retain];
    }
    [renderers put:[attributeType className] value:r];
    if ( recursive ) {
        [self load];
        STGroup *g;
        for ( g in imports )
            [g registerRenderer:attributeType r:r recurs:YES];
    }
}

/** Get renderer for class T associated with this group.
 *
 *  For non-imported groups and object-to-render of class T, use renderer
 *  (if any) registered for T.  For imports, any renderer
 *  set on import group is ignored even when using an imported template.
 *  You should set the renderer on the main group
 *  you use (or all to be sure).  I look at import groups as
 *  "helpers" that should give me templates and nothing else. If you
 *  have multiple renderers for String, say, then just make uber combined
 *  renderer with more specific format names.
 */
- (id<AttributeRenderer>) getAttributeRenderer:(id)attributeType
{
    if ( renderers == nil )     return nil;
    id<AttributeRenderer> r = nil;
    if ( typeToRendererCache != nil ) {
        r = [typeToRendererCache get:[attributeType className]];
        if ( r != nil ) return r;
    }
    LHMEntry *e;
    NSString *key;
    LHMEntryIterator *it = (LHMEntryIterator *)[renderers newKeyIterator];
    while ( [it hasNext] ) {
        key = [it next];
        // t works for attributeType if attributeType subclasses t or implements
        id rendererClass = objc_getClass([key UTF8String]);
        if ( [[attributeType class] isSubclassOfClass:rendererClass] ) {
            r = [renderers get:key];
            if ( typeToRendererCache == nil ) {
                typeToRendererCache = [[LinkedHashMap newLinkedHashMap:16] retain];
            }
            [typeToRendererCache put:[attributeType className] value:r];
            return r;
        }
    }
    return nil;
}

/** StringTemplate object factory; each group can have its own. */
- (ST *) createStringTemplate:(CompiledST *)anImpl
{
    ST *st = [ST newST];
    st.impl = [anImpl retain];
    st.groupThatCreatedThisInstance = self;
    if ( anImpl.formalArguments != nil ) {
        NSInteger cnt = [anImpl.formalArguments count];
        st.locals = [[AMutableArray arrayWithCapacity:cnt] retain];
        for ( NSInteger i = 0; i < cnt; i++ ) {
            [st.locals addObject:ST.EMPTY_ATTR];
        }
    }
    return st;
}

/** differentiate so we can avoid having creation events for regions,
 *  map operations, and other "new ST" events used during interp.
 */
- (ST *) createStringTemplateInternally:(CompiledST *)anImpl
{
    ST *st = [self createStringTemplate:anImpl];
    if ( trackCreationEvents && st.debugState!=nil ) {
        st.debugState.newSTEvent = nil; // toss it out
    }
    return st;
}

- (ST *) createStringTemplateInternallyWithProto:(ST *)proto
{
    return [ST newSTWithProto:proto]; // no need to wack debugState; not set in ST(proto).
}

- (NSString *)getName
{
    return @"<no name>";
}

- (NSString *)getFileName
{
    return nil;
}

/** Return root dir if this is group dir; return dir containing group file
 *  if this is group file.  This is derived from original incoming
 *  dir or filename.  If it was absolute, this should come back
 *  as full absolute path.  If it was org/foo/templates then this should
 *  be org/foo/templates.  org/foo/templates/main.stg ->
 *  org/foo/templates.
 */
- (NSURL *)getRootDirURL
{
    return nil;
}

- (NSURL *)getURL:(NSString *)fileName
{
    NSURL *url = nil;
    //[NSURL 
/*
    Class cl = Thread.currentThread().getContextClassLoader();
    url = cl.getResource(fileName);
    if ( url==nil ) {
        cl = [[self class] getClassLoader];
        url = [cl getResource:fileName];
    }
 */
    return url;
}

- (NSString *) description
{
    return [self getName];
}

- (NSString *) show
{
    NSMutableString *buf = [NSMutableString stringWithCapacity:16];
    if (imports != nil && [imports count] > 0) [buf appendFormat:@" : %@", imports];

    NSString *aName;
    LinkedHashIterator *it = (LinkedHashIterator *)[templates newKeyIterator];
    while ( [it hasNext] ) {
        aName = (NSString *)[it next];
        CompiledST *c = [self rawGetTemplate:aName];
        if (c.isAnonSubtemplate || c == CompiledST.NOT_FOUND_ST)
            continue;
        aName = [aName lastPathComponent];
        [buf appendFormat:@"%@(", aName];
        if (c.formalArguments != nil)
            [buf appendString:[Misc join:[[[c.formalArguments values] toArray] objectEnumerator] separator:@","]];
        [buf appendFormat:@") ::= <<%@%@%@>>%@", Misc.newline, c.template, Misc.newline, Misc.newline];
    }
    return [buf description];
}

- (id<STErrorListener>)getListener
{
    return errMgr.listener;
}

- (void) setListener:(id<STErrorListener>)listener
{
    errMgr = [[ErrorManager newErrorManagerWithListener:listener] retain];
}

- (AMutableArray *) getTemplateNames
{
    [self load];
    AMutableArray *result = [AMutableArray arrayWithCapacity:16];
    LHMEntryIterator *it = [templates newEntryIterator];
    LHMEntry *e;
    while ( [it hasNext] ) {
        e = [it next];
        if ( e.value != CompiledST.NOT_FOUND_ST ) {
            [result addObject:e.key];
        }
    }
    return result;
}

@end
