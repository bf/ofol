local syntax = require "lib.syntax"

syntax.add {
  name = "FreeFEM++",
  files = {
    "%.edp$", "%.ffp$"
  },
  comment = "//",
  block_comment = { "/*", "*/" },
  patterns = {
    { pattern = "//.*",                     type = "comment" },
    { pattern = { "/%*", "%*/" },           type = "comment" },
    { pattern = { '"', '"', '\\' },         type = "string" },
    { pattern = "0x%x+[%x']*",              type = "number" },
    { pattern = "%d+[%d%.'eE]*f?",          type = "number" },
    { pattern = "%.?%d+[%d']*f?",           type = "number" },
    { pattern = "[%+%-=/%*%^%%<>!~|:&]",    type = "operator" },
    { pattern = "##",                       type = "operator" },
    { pattern = "struct%s()[%a_][%w_]*",    type = { "keyword", "keyword2" } },
    { pattern = "class%s()[%a_][%w_]*",     type = { "keyword", "keyword2" } },
    { pattern = "union%s()[%a_][%w_]*",     type = { "keyword", "keyword2" } },
    { pattern = "namespace%s()[%a_][%w_]*", type = { "keyword", "keyword2" } },
    -- static declarations
    {
      pattern = "static()%s+()inline",
      type = { "keyword", "normal", "keyword" }
    },
    {
      pattern = "static()%s+()const",
      type = { "keyword", "normal", "keyword" }
    },
    {
      pattern = "static()%s+()[%a_][%w_]*",
      type = { "keyword", "normal", "literal" }
    },
    -- match method type declarations
    {
      pattern = "[%a_][%w_]*()%s*()%**()%s*()[%a_][%w_]*()%s*()::",
      type = {
        "literal", "normal", "operator", "normal",
        "literal", "normal", "operator"
      }
    },
    -- match function type declarations
    {
      pattern = "[%a_][%w_]*()%*+()%s+()[%a_][%w_]*%f[%(]",
      type = { "literal", "operator", "normal", "function" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()%*+()[%a_][%w_]*%f[%(]",
      type = { "literal", "normal", "operator", "function" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()[%a_][%w_]*%f[%(]",
      type = { "literal", "normal", "function" }
    },
    -- match variable type declarations
    {
      pattern = "[%a_][%w_]*()%*+()%s+()[%a_][%w_]*",
      type = { "literal", "operator", "normal", "normal" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()%*+()[%a_][%w_]*",
      type = { "literal", "normal", "operator", "normal" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()[%a_][%w_]*()%s*()[;,%[%)]",
      type = { "literal", "normal", "normal", "normal", "normal" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()[%a_][%w_]*()%s*()=",
      type = { "literal", "normal", "normal", "normal", "operator" }
    },
    {
      pattern = "[%a_][%w_]*()&()%s+()[%a_][%w_]*",
      type = { "literal", "operator", "normal", "normal" }
    },
    {
      pattern = "[%a_][%w_]*()%s+()&()[%a_][%w_]*",
      type = { "literal", "normal", "operator", "normal" }
    },
    -- Match scope operator element access
    {
      pattern = "[%a_][%w_]*()%s*()::",
      type = { "literal", "normal", "operator" }
    },
    -- Uppercase constants of at least 2 chars in len
    {
      pattern = "_?%u[%u_][%u%d_]*%f[%s%+%*%-%.%)%]}%?%^%%=/<>~|&;:,!]",
      type = "number"
    },
    -- Magic constants
    { pattern = "__[%u%l]+__",      type = "number" },
    -- all other functions
    { pattern = "[%a_][%w_]*%f[(]", type = "function" },
    -- Macros
    {
      pattern = "^%s*#%s*define%s+()[%a_][%a%d_]*",
      type = { "keyword", "symbol" }
    },
    {
      pattern = "#%s*include%s+()<.->",
      type = { "keyword", "string" }
    },
    { pattern = "%f[#]#%s*[%a_][%w_]*", type = "keyword" },
    -- Everything else to make the tokenizer work properly
    { pattern = "[%a_][%w_]*",          type = "symbol" },
  },
  symbols = {
    ["alignof"]           = "keyword",
    ["alignas"]           = "keyword",
    ["and"]               = "keyword",
    ["and_eq"]            = "keyword",
    ["not"]               = "keyword",
    ["not_eq"]            = "keyword",
    ["or"]                = "keyword",
    ["or_eq"]             = "keyword",
    ["xor"]               = "keyword",
    ["xor_eq"]            = "keyword",
    ["private"]           = "keyword",
    ["protected"]         = "keyword",
    ["public"]            = "keyword",
    ["register"]          = "keyword",
    ["nullptr"]           = "keyword",
    ["operator"]          = "keyword",
    ["asm"]               = "keyword",
    ["bitand"]            = "keyword",
    ["bitor"]             = "keyword",
    ["catch"]             = "keyword",
    ["throw"]             = "keyword",
    ["try"]               = "keyword",
    ["class"]             = "keyword",
    ["compl"]             = "keyword",
    ["explicit"]          = "keyword",
    ["export"]            = "keyword",
    ["concept"]           = "keyword",
    ["consteval"]         = "keyword",
    ["constexpr"]         = "keyword",
    ["constinit"]         = "keyword",
    ["const_cast"]        = "keyword",
    ["dynamic_cast"]      = "keyword",
    ["reinterpret_cast"]  = "keyword",
    ["static_cast"]       = "keyword",
    ["static_assert"]     = "keyword",
    ["template"]          = "keyword",
    ["this"]              = "keyword",
    ["thread_local"]      = "keyword",
    ["requires"]          = "keyword",
    ["co_wait"]           = "keyword",
    ["co_return"]         = "keyword",
    ["co_yield"]          = "keyword",
    ["decltype"]          = "keyword",
    ["delete"]            = "keyword",
    ["friend"]            = "keyword",
    ["typeid"]            = "keyword",
    ["typename"]          = "keyword",
    ["mutable"]           = "keyword",
    ["override"]          = "keyword",
    ["virtual"]           = "keyword",
    ["using"]             = "keyword",
    ["namespace"]         = "keyword",
    ["new"]               = "keyword",
    ["noexcept"]          = "keyword",
    ["if"]                = "keyword",
    ["then"]              = "keyword",
    ["else"]              = "keyword",
    ["elseif"]            = "keyword",
    ["do"]                = "keyword",
    ["while"]             = "keyword",
    ["for"]               = "keyword",
    ["break"]             = "keyword",
    ["continue"]          = "keyword",
    ["return"]            = "keyword",
    ["goto"]              = "keyword",
    ["struct"]            = "keyword",
    ["union"]             = "keyword",
    ["typedef"]           = "keyword",
    ["enum"]              = "keyword",
    ["extern"]            = "keyword",
    ["static"]            = "keyword",
    ["volatile"]          = "keyword",
    ["const"]             = "keyword",
    ["inline"]            = "keyword",
    ["case"]              = "keyword",
    ["default"]           = "keyword",
    ["auto"]              = "keyword",
    ["void"]              = "keyword2",
    ["int"]               = "keyword2",
    ["short"]             = "keyword2",
    ["long"]              = "keyword2",
    ["float"]             = "keyword2",
    ["double"]            = "keyword2",
    ["char"]              = "keyword2",
    ["unsigned"]          = "keyword2",
    ["bool"]              = "keyword2",
    ["true"]              = "literal",
    ["false"]             = "literal",
    ["NULL"]              = "literal",
    ["wchar_t"]           = "keyword2",
    ["char8_t"]           = "keyword2",
    ["char16_t"]          = "keyword2",
    ["char32_t"]          = "keyword2",
    ["#include"]          = "keyword",
    ["#if"]               = "keyword",
    ["#ifdef"]            = "keyword",
    ["#ifndef"]           = "keyword",
    ["#elif"]             = "keyword",
    ["#else"]             = "keyword",
    ["#elseif"]           = "keyword",
    ["#endif"]            = "keyword",
    ["#define"]           = "keyword",
    ["#warning"]          = "keyword",
    ["#error"]            = "keyword",
    ["#pragma"]           = "keyword",
    ["end"]               = "keyword",
    ["element"]           = "keyword",
    ["label"]             = "keyword",
    ["measure"]           = "keyword",
    ["mesure"]            = "keyword",
    ["Element"]           = "keyword",
    ["whoinElement"]      = "keyword",
    ["region"]            = "keyword",
    ["R3"]                = "keyword",
    ["vertex"]            = "keyword",
    ["im"]                = "keyword",
    ["l1"]                = "keyword",
    ["l2"]                = "keyword",
    ["linfty"]            = "keyword",
    ["max"]               = "keyword",
    ["min"]               = "keyword",
    ["re"]                = "keyword",
    ["sum"]               = "keyword",
    ["quantile"]          = "keyword",
    ["sort"]              = "keyword",
    ["x"]                 = "keyword",
    ["y"]                 = "keyword",
    ["z"]                 = "keyword",
    ["length"]            = "keyword",
    ["area"]              = "keyword",
    ["coef"]              = "keyword",
    ["diag"]              = "keyword",
    ["m"]                 = "keyword",
    ["n"]                 = "keyword",
    ["nbcoef"]            = "keyword",
    ["nnz"]               = "keyword",
    ["resize"]            = "keyword",
    ["size"]              = "keyword",
    ["imax"]              = "keyword",
    ["imin"]              = "keyword",
    ["N"]                 = "keyword",
    ["P"]                 = "keyword",
    ["nuTriangle"]        = "keyword",
    ["ndof"]              = "keyword",
    ["ndofK"]             = "keyword",
    ["nt"]                = "keyword",
    ["be"]                = "keyword",
    ["hmax"]              = "keyword",
    ["hmin"]              = "keyword",
    ["nbe"]               = "keyword",
    ["nv"]                = "keyword",
    ["bordermesure"]      = "keyword",
    ["eof"]               = "keyword",
    ["good"]              = "keyword",
    ["fixed"]             = "keyword",
    ["flush"]             = "keyword",
    ["noshowbase"]        = "keyword",
    ["noshowpos"]         = "keyword",
    ["precision"]         = "keyword",
    ["scientific"]        = "keyword",
    ["seekp"]             = "keyword",
    ["showbase"]          = "keyword",
    ["showpos"]           = "keyword",
    ["tellp"]             = "keyword",
    ["ARGV"]              = "keyword",
    ["CG"]                = "keyword",
    ["CPUTime"]           = "keyword",
    ["Cholesky"]          = "keyword",
    ["Cofactor"]          = "keyword",
    ["Crout"]             = "keyword",
    ["Edge03d"]           = "keyword",
    ["GMRES"]             = "keyword",
    ["HaveUMFPACK"]       = "keyword",
    ["LU"]                = "keyword",
    ["NaN"]               = "keyword",
    ["P0"]                = "keyword",
    ["P03d"]              = "keyword",
    ["P0VF"]              = "keyword",
    ["P0edge"]            = "keyword",
    ["P1"]                = "keyword",
    ["P13d"]              = "keyword",
    ["P1b"]               = "keyword",
    ["P1b3d"]             = "keyword",
    ["P1dc"]              = "keyword",
    ["P1nc"]              = "keyword",
    ["P2"]                = "keyword",
    ["P23d"]              = "keyword",
    ["P2b"]               = "keyword",
    ["P2dc"]              = "keyword",
    ["P2h"]               = "keyword",
    ["RT0"]               = "keyword",
    ["RT03d"]             = "keyword",
    ["RT0Ortho"]          = "keyword",
    ["RTmodif"]           = "keyword",
    ["UMFPACK"]           = "keyword",
    ["append"]            = "keyword",
    ["binary"]            = "keyword",
    ["hTriangle"]         = "keyword",
    ["havesparsesolver"]  = "keyword",
    ["inside"]            = "keyword",
    ["lenEdge"]           = "keyword",
    ["nTonEdge"]          = "keyword",
    ["nuEdge"]            = "keyword",
    ["pi"]                = "keyword",
    ["qf1pE"]             = "keyword",
    ["qf1pElump"]         = "keyword",
    ["qf1pT"]             = "keyword",
    ["qf1pTlump"]         = "keyword",
    ["qf2pE"]             = "keyword",
    ["qf2pT"]             = "keyword",
    ["qf2pT4P1"]          = "keyword",
    ["qf3pE"]             = "keyword",
    ["qf4pE"]             = "keyword",
    ["qf5pE"]             = "keyword",
    ["qf5pT"]             = "keyword",
    ["qf7pT"]             = "keyword",
    ["qf9pT"]             = "keyword",
    ["qfV1"]              = "keyword",
    ["qfV1lump"]          = "keyword",
    ["qfV2"]              = "keyword",
    ["qfV5"]              = "keyword",
    ["searchMethod"]      = "keyword",
    ["sparsesolver"]      = "keyword",
    ["sparsesolverSym"]   = "keyword",
    ["storagetotal"]      = "keyword",
    ["storageused"]       = "keyword",
    ["verbosity"]         = "keyword",
    ["version"]           = "keyword",
    ["volume"]            = "keyword",
    ["volumelevelset"]    = "keyword",
    ["wait"]              = "keyword",
    ["ShowAlloc"]         = "keyword",
    ["Newton"]            = "keyword",
    ["NoGraphicWindow"]   = "keyword",
    ["NoUseOfWait"]       = "keyword",
    ["SameMesh"]          = "keyword",
    ["Unique"]            = "keyword",
    ["arealevelset"]      = "keyword",
    ["average"]           = "keyword",
    ["chtmpdir"]          = "keyword",
    ["time"]              = "keyword",
    ["fill"]              = "keyword",
    ["value"]             = "keyword",
    ["nbiso"]             = "keyword",
    ["coeff"]             = "keyword",
    ["dataname"]          = "keyword",
    ["order"]             = "keyword",
    ["mpirank"]           = "keyword",
    ["mpiCommWorld"]      = "keyword",
    ["mpiGroup"]          = "keyword",
    ["mpiRequest"]        = "keyword",
    ["sparams"]           = "keyword",
    ["mpisize"]           = "keyword",
    ["mpiUndefined"]      = "keyword",
    ["mpiAnySource"]      = "keyword",
    ["communicator"]      = "keyword",
    ["worker"]            = "keyword",
    ["dim"]               = "keyword",
    ["cmm"]               = "keyword",
    ["solver"]            = "keyword",
    ["aniso"]             = "keyword",
    ["nbvx"]              = "keyword",
    ["abserror"]          = "keyword",
    ["anisomax"]          = "keyword",
    ["cutoff"]            = "keyword",
    ["err"]               = "keyword",
    ["errg"]              = "keyword",
    ["inquire"]           = "keyword",
    ["IsMetric"]          = "keyword",
    ["iso"]               = "keyword",
    ["keepbackvertices"]  = "keyword",
    ["maxsubdiv"]         = "keyword",
    ["metric"]            = "keyword",
    ["nbjacoby"]          = "keyword",
    ["nbsmooth"]          = "keyword",
    ["nomeshgeneration"]  = "keyword",
    ["omega"]             = "keyword",
    ["periodic"]          = "keyword",
    ["powerin"]           = "keyword",
    ["ratio"]             = "keyword",
    ["rescaling"]         = "keyword",
    ["splitin2"]          = "keyword",
    ["splitpbedge"]       = "keyword",
    ["thetamax"]          = "keyword",
    ["uniform"]           = "keyword",
    ["fixedborder"]       = "keyword",
    ["flags"]             = "keyword",
    ["ivalue"]            = "keyword",
    ["maxit"]             = "keyword",
    ["mode"]              = "keyword",
    ["ncv"]               = "keyword",
    ["nev"]               = "keyword",
    ["rawvector"]         = "keyword",
    ["sigma"]             = "keyword",
    ["sym"]               = "keyword",
    ["tol"]               = "keyword",
    ["vector"]            = "keyword",
    ["which"]             = "keyword",
    ["op"]                = "keyword",
    ["t"]                 = "keyword",
    ["eps"]               = "keyword",
    ["nbiter"]            = "keyword",
    ["precon"]            = "keyword",
    ["veps"]              = "keyword",
    ["tgv"]               = "keyword",
    ["tolpivot"]          = "keyword",
    ["meditff"]           = "keyword",
    ["save"]              = "keyword",
    ["orientation"]       = "keyword",
    ["ptmerge"]           = "keyword",
    ["transfo"]           = "keyword",
    ["optimize"]          = "keyword",
    ["aspectratio"]       = "keyword",
    ["bb"]                = "keyword",
    ["boundary"]          = "keyword",
    ["bw"]                = "keyword",
    ["cut"]               = "keyword",
    ["grey"]              = "keyword",
    ["hsv"]               = "keyword",
    ["nbarrow"]           = "keyword",
    ["ps"]                = "keyword",
    ["varrow"]            = "keyword",
    ["viso"]              = "keyword",
    ["init"]              = "keyword",
    ["strategy"]          = "keyword",
    ["tolpivotsym"]       = "keyword",
    ["facetcl"]           = "keyword",
    ["holelist"]          = "keyword",
    ["nboffacetcl"]       = "keyword",
    ["nbofregions"]       = "keyword",
    ["regionlist"]        = "keyword",
    ["switch"]            = "keyword",
    ["refface"]           = "keyword",
    ["split"]             = "keyword",
    ["zbound"]            = "keyword",
    ["labeldown"]         = "keyword",
    ["labelmid"]          = "keyword",
    ["labelup"]           = "keyword",
    ["opt"]               = "keyword",
    ["mpiMAX"]            = "keyword",
    ["mpiMIN"]            = "keyword",
    ["mpiSUM"]            = "keyword",
    ["mpiPROD"]           = "keyword",
    ["mpiLAND"]           = "keyword",
    ["mpiLOR"]            = "keyword",
    ["mpiLXOR"]           = "keyword",
    ["mpiBAND"]           = "keyword",
    ["mpiBXOR"]           = "keyword",
    ["border"]            = "keyword2",
    ["Cmapmatrix"]        = "keyword2",
    ["Cmatrix"]           = "keyword2",
    ["complex"]           = "keyword2",
    ["fespace"]           = "keyword2",
    ["func"]              = "keyword2",
    ["ifstream"]          = "keyword2",
    ["mapmatrix"]         = "keyword2",
    ["matrix"]            = "keyword2",
    ["mesh"]              = "keyword2",
    ["mesh3"]             = "keyword2",
    ["ofstream"]          = "keyword2",
    ["problem"]           = "keyword2",
    ["real"]              = "keyword2",
    ["solve"]             = "keyword2",
    ["string"]            = "keyword2",
    ["varf"]              = "keyword2",
    ["macro"]             = "keyword2",
    ["dmatrix"]           = "keyword2",
    ["adj"]               = "function",
    ["find"]              = "function",
    ["rfind"]             = "function",
    ["seekg"]             = "function",
    ["tellg"]             = "function",
    ["AddLayers"]         = "function",
    ["AffineCG"]          = "function",
    ["AffineGMRES"]       = "function",
    ["BFGS"]              = "function",
    ["EigenValue"]        = "function",
    ["LinearCG"]          = "function",
    ["LinearGMRES"]       = "function",
    ["NLCG"]              = "function",
    ["abs"]               = "function",
    ["acos"]              = "function",
    ["acosh"]             = "function",
    ["adaptmesh"]         = "function",
    ["arg"]               = "function",
    ["asin"]              = "function",
    ["asinh"]             = "function",
    ["assert"]            = "function",
    ["atan"]              = "function",
    ["atan2"]             = "function",
    ["atanh"]             = "function",
    ["atof"]              = "function",
    ["atoi"]              = "function",
    ["boundingbox"]       = "function",
    ["buildmesh"]         = "function",
    ["buildmeshborder"]   = "function",
    ["ceil"]              = "function",
    ["change"]            = "function",
    ["checkmovemesh"]     = "function",
    ["clock"]             = "function",
    ["complexEigenValue"] = "function",
    ["conj"]              = "function",
    ["convect"]           = "function",
    ["cos"]               = "function",
    ["cosh"]              = "function",
    ["defaultoUMFPACK"]   = "function",
    ["defaultsolver"]     = "function",
    ["defaulttoCG"]       = "function",
    ["defaulttoGMRES"]    = "function",
    ["defaulttoUMFPACK"]  = "function",
    ["det"]               = "function",
    ["dumptable"]         = "function",
    ["dx"]                = "function",
    ["dxx"]               = "function",
    ["dxy"]               = "function",
    ["dxz"]               = "function",
    ["dy"]                = "function",
    ["dyx"]               = "function",
    ["dyy"]               = "function",
    ["dyz"]               = "function",
    ["dz"]                = "function",
    ["dzx"]               = "function",
    ["dzy"]               = "function",
    ["dzz"]               = "function",
    ["emptymesh"]         = "function",
    ["erf"]               = "function",
    ["erfc"]              = "function",
    ["exec"]              = "function",
    ["exit"]              = "function",
    ["exp"]               = "function",
    ["floor"]             = "function",
    ["getline"]           = "function",
    ["hypot"]             = "function",
    ["imag"]              = "function",
    ["int1d"]             = "function",
    ["int2d"]             = "function",
    ["int3d"]             = "function",
    ["intallVFedges"]     = "function",
    ["intalledges"]       = "function",
    ["intallfaces"]       = "function",
    ["interplotematrix"]  = "function",
    ["interpolate"]       = "function",
    ["isInf"]             = "function",
    ["isNaN"]             = "function",
    ["isNormal"]          = "function",
    ["j0"]                = "function",
    ["j1"]                = "function",
    ["jn"]                = "function",
    ["jump"]              = "function",
    ["lgamma"]            = "function",
    ["log"]               = "function",
    ["log10"]             = "function",
    ["lrint"]             = "function",
    ["lround"]            = "function",
    ["ltime"]             = "function",
    ["mean"]              = "function",
    ["movemesh"]          = "function",
    ["newconvect"]        = "function",
    ["norm"]              = "function",
    ["on"]                = "function",
    ["otherside"]         = "function",
    ["plot"]              = "function",
    ["polar"]             = "function",
    ["pow"]               = "function",
    ["randinit"]          = "function",
    ["randint31"]         = "function",
    ["randint32"]         = "function",
    ["randreal1"]         = "function",
    ["randreal2"]         = "function",
    ["randreal3"]         = "function",
    ["randres53"]         = "function",
    ["readmesh"]          = "function",
    ["readmesh3"]         = "function",
    ["renumbering"]       = "function",
    ["restrict"]          = "function",
    ["rint"]              = "function",
    ["round"]             = "function",
    ["savemesh"]          = "function",
    ["savesurfacemesh"]   = "function",
    ["set"]               = "function",
    ["setw"]              = "function",
    ["showCPU"]           = "function",
    ["sin"]               = "function",
    ["sinh"]              = "function",
    ["splitmesh"]         = "function",
    ["sqr"]               = "function",
    ["sqrt"]              = "function",
    ["square"]            = "function",
    ["system"]            = "function",
    ["tan"]               = "function",
    ["tanh"]              = "function",
    ["tgamma"]            = "function",
    ["toCarray"]          = "function",
    ["toRarray"]          = "function",
    ["toZarray"]          = "function",
    ["trace"]             = "function",
    ["triangulate"]       = "function",
    ["trunc"]             = "function",
    ["y0"]                = "function",
    ["y1"]                = "function",
    ["yn"]                = "function",
    ["savevtk"]           = "function",
    ["mshmet"]            = "function",
    ["savesol"]           = "function",
    ["gmshload"]          = "function",
    ["gmshload3"]         = "function",
    ["mpiBarrier"]        = "function",
    ["mpiSize"]           = "function",
    ["Irecv"]             = "function",
    ["Isend"]             = "function",
    ["processor"]         = "function",
    ["mpiWaitAny"]        = "function",
    ["mpiWait"]           = "function",
    ["mpiRank"]           = "function",
    ["metis"]             = "function",
    ["metisdual"]         = "function",
    ["broadcast"]         = "function",
    ["scotch"]            = "function",
    ["parmetis"]          = "function",
    ["mpiWtime"]          = "function",
    ["buildlayers"]       = "function",
    ["mmg3d"]             = "function",
    ["processorblock"]    = "function",
    ["mpiWaitAll"]        = "function",
    ["mpiWtick"]          = "function",
    ["Send"]              = "function",
    ["Recv"]              = "function",
    ["mpiAlltoall"]       = "function",
    ["mpiGather"]         = "function",
    ["mpiScatter"]        = "function",
    ["mpiReduce"]         = "function",
    ["mpiAllReduce"]      = "function",
    ["mpiReduceScatter"]  = "function",
  },
}
