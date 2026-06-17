(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.la(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.i(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.dS(b)
return new t(c,this)}:function(){if(t===null)t=A.dS(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.dS(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
hE(a,b){if(a<0||a>4294967295)throw A.c(A.a_(a,0,4294967295,"length",null))
return J.dx(new Array(a),b)},
cz(a,b){if(a<0)throw A.c(A.dp("Length must be a non-negative integer: "+a))
return A.i(new Array(a),b.i("k<0>"))},
dx(a,b){var t=A.i(a,b.i("k<0>"))
t.$flags=1
return t},
hF(a,b){var t=u.V
return J.fy(t.a(a),t.a(b))},
ef(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
hG(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.ef(s))break;++b}return b},
hH(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.b(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.ef(r))break}return b},
aA(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.b8.prototype
return J.bY.prototype}if(typeof a=="string")return J.ae.prototype
if(a==null)return J.b9.prototype
if(typeof a=="boolean")return J.bX.prototype
if(Array.isArray(a))return J.k.prototype
if(typeof a=="function")return J.ba.prototype
if(typeof a=="object"){if(a instanceof A.p){return a}else{return J.aL.prototype}}if(!(a instanceof A.p))return J.ab.prototype
return a},
dT(a){if(a==null)return a
if(Array.isArray(a))return J.k.prototype
if(!(a instanceof A.p))return J.ab.prototype
return a},
k9(a){if(typeof a=="string")return J.ae.prototype
if(a==null)return a
if(Array.isArray(a))return J.k.prototype
if(!(a instanceof A.p))return J.ab.prototype
return a},
ka(a){if(typeof a=="number")return J.aI.prototype
if(typeof a=="string")return J.ae.prototype
if(a==null)return a
if(!(a instanceof A.p))return J.ab.prototype
return a},
fb(a){if(typeof a=="string")return J.ae.prototype
if(a==null)return a
if(!(a instanceof A.p))return J.ab.prototype
return a},
Z(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.aA(a).B(a,b)},
b0(a,b){return J.dT(a).l(a,b)},
dZ(a,b){return J.fb(a).aw(a,b)},
fy(a,b){return J.ka(a).A(a,b)},
fz(a,b){return J.dT(a).I(a,b)},
t(a){return J.aA(a).gv(a)},
dn(a){return J.dT(a).gq(a)},
bC(a){return J.k9(a).gt(a)},
fA(a){return J.aA(a).gM(a)},
fB(a,b,c){return J.fb(a).D(a,b,c)},
bD(a){return J.aA(a).j(a)},
bU:function bU(){},
bX:function bX(){},
b9:function b9(){},
aL:function aL(){},
af:function af(){},
cN:function cN(){},
ab:function ab(){},
ba:function ba(){},
k:function k(a){this.$ti=a},
bW:function bW(){},
cA:function cA(a){this.$ti=a},
b1:function b1(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aI:function aI(){},
b8:function b8(){},
bY:function bY(){},
ae:function ae(){}},A={dy:function dy(){},
A(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
br(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
f6(a,b,c){return a},
dU(a){var t,s
for(t=$.N.length,s=0;s<t;++s)if(a===$.N[s])return!0
return!1},
eq(a,b,c,d){A.dH(b,"start")
A.dH(c,"end")
if(b>c)A.aZ(A.a_(b,0,c,"start",null))
return new A.bq(a,b,c,d.i("bq<0>"))},
bV(){return new A.bp("No element")},
c0:function c0(a){this.a=a},
cQ:function cQ(){},
b7:function b7(){},
F:function F(){},
bq:function bq(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
bf:function bf(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
L:function L(a,b,c){this.a=a
this.b=b
this.$ti=c},
as:function as(a,b,c){this.a=a
this.b=b
this.$ti=c},
bu:function bu(a,b,c){this.a=a
this.b=b
this.$ti=c},
hC(){throw A.c(A.es("Cannot modify constant Set"))},
fg(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
r(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.bD(a)
return t},
bj(a){var t,s=$.ei
if(s==null)s=$.ei=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
hP(a,b){var t,s=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(s==null)return null
if(3>=s.length)return A.b(s,3)
t=s[3]
if(t!=null)return parseInt(a,10)
if(s[2]!=null)return parseInt(a,16)
return null},
hO(a){var t,s
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
t=parseFloat(a)
if(isNaN(t)){s=B.b.G(a)
if(s==="NaN"||s==="+NaN"||s==="-NaN")return t
return null}return t},
c2(a){var t,s,r,q
if(a instanceof A.p)return A.M(A.cj(a),null)
t=J.aA(a)
if(t===B.bC||t===B.bD||u.A.b(a)){s=B.b0(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.M(A.cj(a),null)},
ej(a){var t,s,r
if(a==null||typeof a=="number"||A.dQ(a))return J.bD(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.ad)return a.j(0)
if(a instanceof A.a1)return a.au(!0)
t=$.fu()
for(s=0;s<1;++s){r=t[s].bh(a)
if(r!=null)return r}return"Instance of '"+A.c2(a)+"'"},
z(a){var t
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.a.ar(t,10)|55296)>>>0,t&1023|56320)}}throw A.c(A.a_(a,0,1114111,null,null))},
b(a,b){if(a==null)J.bC(a)
throw A.c(A.f8(a,b))},
f8(a,b){var t,s="index"
if(!A.eW(b))return new A.T(!0,b,s,null)
t=J.bC(a)
if(b<0||b>=t)return A.dw(b,t,a,s)
return A.ek(b,s)},
k_(a){return new A.T(!0,a,null,null)},
c(a){return A.E(a,new Error())},
E(a,b){var t
if(a==null)a=new A.bs()
b.dartException=a
t=A.lb
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
lb(){return J.bD(this.dartException)},
aZ(a,b){throw A.E(a,b==null?new Error():b)},
ck(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.aZ(A.iF(a,b,c),t)},
iF(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.bt("'"+t+"': Cannot "+p+" "+m+l+o)},
O(a){throw A.c(A.U(a))},
aa(a){var t,s,r,q,p,o
a=A.fe(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.i([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.cR(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
cS(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
er(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
dz(a,b){var t=b==null,s=t?null:b.method
return new A.bZ(a,s,t?null:b.receiver)},
dW(a){if(a==null)return new A.cL(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.aD(a,a.dartException)
return A.jZ(a)},
aD(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
jZ(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.a.ar(s,16)&8191)===10)switch(r){case 438:return A.aD(a,A.dz(A.r(t)+" (Error "+r+")",null))
case 445:case 5007:A.r(t)
return A.aD(a,new A.bi())}}if(a instanceof TypeError){q=$.fk()
p=$.fl()
o=$.fm()
n=$.fn()
m=$.fq()
l=$.fr()
k=$.fp()
$.fo()
j=$.ft()
i=$.fs()
h=q.F(t)
if(h!=null)return A.aD(a,A.dz(A.Y(t),h))
else{h=p.F(t)
if(h!=null){h.method="call"
return A.aD(a,A.dz(A.Y(t),h))}else if(o.F(t)!=null||n.F(t)!=null||m.F(t)!=null||l.F(t)!=null||k.F(t)!=null||n.F(t)!=null||j.F(t)!=null||i.F(t)!=null){A.Y(t)
return A.aD(a,new A.bi())}}return A.aD(a,new A.c8(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.bo()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.aD(a,new A.T(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.bo()
return a},
dV(a){if(a==null)return J.t(a)
if(typeof a=="object")return A.bj(a)
return J.t(a)},
k1(a){if(typeof a=="number")return B.F.gv(a)
if(a instanceof A.ci)return A.bj(a)
if(a instanceof A.a1)return a.gv(a)
return A.dV(a)},
k8(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.u(0,a[t],a[s])}return b},
iQ(a,b,c,d,e,f){u.Z.a(a)
switch(A.R(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(new A.cV("Unsupported number of arguments for wrapped closure"))},
k2(a,b){var t=a.$identity
if(!!t)return t
t=A.k3(a,b)
a.$identity=t
return t},
k3(a,b){var t
switch(b){case 0:t=a.$0
break
case 1:t=a.$1
break
case 2:t=a.$2
break
case 3:t=a.$3
break
case 4:t=a.$4
break
default:t=null}if(t!=null)return t.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.iQ)},
hB(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.c4().constructor.prototype):Object.create(new A.aE(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.eb(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.hx(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.eb(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
hx(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fC)}throw A.c("Error in functionType of tearoff")},
hy(a,b,c,d){var t=A.e2
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
eb(a,b,c,d){if(c)return A.hA(a,b,d)
return A.hy(b.length,d,a,b)},
hz(a,b,c,d){var t=A.e2,s=A.fD
switch(b?-1:a){case 0:throw A.c(new A.c3("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
hA(a,b,c){var t,s
if($.e0==null)$.e0=A.e_("interceptor")
if($.e1==null)$.e1=A.e_("receiver")
t=b.length
s=A.hz(t,c,a,b)
return s},
dS(a){return A.hB(a)},
fC(a,b){return A.bB(v.typeUniverse,A.cj(a.a),b)},
e2(a){return a.a},
fD(a){return a.b},
e_(a){var t,s,r,q=new A.aE("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.c(A.dp("Field name "+a+" not found."))},
fc(a){return v.getIsolateTag(a)},
ig(a,b){var t,s
for(t=0;t<a.length;++t){s=a[t]
if(!(t<b.length))return A.b(b,t)
if(!J.Z(s,b[t]))return!1}return!0},
k5(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
eg(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=function(g,h){try{return new RegExp(g,h)}catch(o){return o}}(a,t+s+r+q+f)
if(p instanceof RegExp)return p
throw A.c(A.ec("Illegal RegExp pattern ("+String(p)+")",a))},
l5(a,b,c){var t=a.indexOf(b,c)
return t>=0},
fa(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
fe(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
S(a,b,c){var t
if(typeof b=="string")return A.l7(a,b,c)
if(b instanceof A.aK){t=b.gap()
t.lastIndex=0
return a.replace(t,A.fa(c))}return A.l6(a,b,c)},
l6(a,b,c){var t,s,r,q
for(t=J.dZ(b,a),t=t.gq(t),s=0,r="";t.k();){q=t.gn()
r=r+a.substring(s,q.ga4())+c
s=q.ga0()}t=r+a.substring(s)
return t.charCodeAt(0)==0?t:t},
l7(a,b,c){var t,s,r
if(b===""){if(a==="")return c
t=a.length
for(s=c,r=0;r<t;++r)s=s+a[r]+c
return s.charCodeAt(0)==0?s:s}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.fe(b),"g"),A.fa(c))},
l8(a,b,c,d){var t=a.indexOf(b,d)
if(t<0)return a
return A.l9(a,t,t+b.length,c)},
l9(a,b,c,d){return a.substring(0,b)+d+a.substring(c)},
aV:function aV(a,b,c){this.a=a
this.b=b
this.c=c},
bv:function bv(a){this.a=a},
b6:function b6(){},
aH:function aH(a,b,c){this.a=a
this.b=b
this.$ti=c},
au:function au(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aG:function aG(){},
an:function an(a,b,c){this.a=a
this.b=b
this.$ti=c},
J:function J(a,b){this.a=a
this.$ti=b},
bm:function bm(){},
cR:function cR(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bi:function bi(){},
bZ:function bZ(a,b,c){this.a=a
this.b=b
this.c=c},
c8:function c8(a){this.a=a},
cL:function cL(a){this.a=a},
ad:function ad(){},
bN:function bN(){},
bO:function bO(){},
c6:function c6(){},
c4:function c4(){},
aE:function aE(a,b){this.a=a
this.b=b},
c3:function c3(a){this.a=a},
V:function V(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cB:function cB(a){this.a=a},
cE:function cE(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
a4:function a4(a,b){this.a=a
this.$ti=b},
ap:function ap(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
d:function d(a,b){this.a=a
this.$ti=b},
be:function be(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
W:function W(a,b){this.a=a
this.$ti=b},
bd:function bd(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
bb:function bb(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
a1:function a1(){},
aT:function aT(){},
aU:function aU(){},
aK:function aK(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
cf:function cf(a){this.b=a},
ca:function ca(a,b,c){this.a=a
this.b=b
this.c=c},
cb:function cb(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
c5:function c5(a,b){this.a=a
this.c=b},
cg:function cg(a,b,c){this.a=a
this.b=b
this.c=c},
ch:function ch(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
dI(a,b){var t=b.c
return t==null?b.c=A.bz(a,"ed",[b.x]):t},
em(a){var t=a.w
if(t===6||t===7)return A.em(a.x)
return t===11||t===12},
hS(a){return a.as},
ki(a,b){var t,s=b.length
for(t=0;t<s;++t)if(!a[t].b(b[t]))return!1
return!0},
D(a){return A.d2(v.typeUniverse,a,!1)},
ay(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.ay(a0,t,a2,a3)
if(s===t)return a1
return A.eE(a0,s,!0)
case 7:t=a1.x
s=A.ay(a0,t,a2,a3)
if(s===t)return a1
return A.eD(a0,s,!0)
case 8:r=a1.y
q=A.aW(a0,r,a2,a3)
if(q===r)return a1
return A.bz(a0,a1.x,q)
case 9:p=a1.x
o=A.ay(a0,p,a2,a3)
n=a1.y
m=A.aW(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.dL(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.aW(a0,k,a2,a3)
if(j===k)return a1
return A.eF(a0,l,j)
case 11:i=a1.x
h=A.ay(a0,i,a2,a3)
g=a1.y
f=A.jW(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.eC(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.aW(a0,e,a2,a3)
p=a1.x
o=A.ay(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.dM(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.c(A.bH("Attempted to substitute unexpected RTI kind "+a))}},
aW(a,b,c,d){var t,s,r,q,p=b.length,o=A.d3(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.ay(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
jX(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.d3(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.ay(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
jW(a,b,c,d){var t,s=b.a,r=A.aW(a,s,c,d),q=b.b,p=A.aW(a,q,c,d),o=b.c,n=A.jX(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.cd()
t.a=r
t.b=p
t.c=n
return t},
i(a,b){a[v.arrayRti]=b
return a},
f7(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.kc(t)
return a.$S()}return null},
kf(a,b){var t
if(A.em(b))if(a instanceof A.ad){t=A.f7(a)
if(t!=null)return t}return A.cj(a)},
cj(a){if(a instanceof A.p)return A.a(a)
if(Array.isArray(a))return A.G(a)
return A.dP(J.aA(a))},
G(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
a(a){var t=a.$ti
return t!=null?t:A.dP(a)},
dP(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.iO(a,t)},
iO(a,b){var t=a instanceof A.ad?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.ip(v.typeUniverse,t.name)
b.$ccache=s
return s},
kc(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.d2(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
kb(a){return A.az(A.a(a))},
dR(a){var t
if(a instanceof A.a1)return A.k6(a.$r,a.ab())
t=a instanceof A.ad?A.f7(a):null
if(t!=null)return t
if(u.R.b(a))return J.fA(a).a
if(Array.isArray(a))return A.G(a)
return A.cj(a)},
az(a){var t=a.r
return t==null?a.r=new A.ci(a):t},
k6(a,b){var t,s,r=b,q=r.length
if(q===0)return u.F
if(0>=q)return A.b(r,0)
t=A.bB(v.typeUniverse,A.dR(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.b(r,s)
t=A.eG(v.typeUniverse,t,A.dR(r[s]))}return A.bB(v.typeUniverse,t,a)},
lc(a){return A.az(A.d2(v.typeUniverse,a,!1))},
iN(a){var t=this
t.b=A.jS(t)
return t.b(a)},
jS(a){var t,s,r,q,p
if(a===u.K)return A.iZ
if(A.aB(a))return A.j4
t=a.w
if(t===6)return A.iL
if(t===1)return A.eY
if(t===7)return A.iT
s=A.jR(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.aB)){a.f="$i"+r
if(r==="ag")return A.iW
if(a===u.m)return A.iV
return A.j3}}else if(t===10){q=A.k5(a.x,a.y)
p=q==null?A.eY:q
return p==null?A.dN(p):p}return A.iJ},
jR(a){if(a.w===8){if(a===u.S)return A.eW
if(a===u.i||a===u.H)return A.iY
if(a===u.N)return A.j2
if(a===u.y)return A.dQ}return null},
iM(a){var t=this,s=A.iI
if(A.aB(t))s=A.iz
else if(t===u.K)s=A.dN
else if(A.aX(t)){s=A.iK
if(t===u.D)s=A.iv
else if(t===u.w)s=A.iy
else if(t===u.c)s=A.is
else if(t===u.n)s=A.eL
else if(t===u.x)s=A.iu
else if(t===u.z)s=A.ix}else if(t===u.S)s=A.R
else if(t===u.N)s=A.Y
else if(t===u.y)s=A.ir
else if(t===u.H)s=A.eK
else if(t===u.i)s=A.it
else if(t===u.m)s=A.iw
t.a=s
return t.a(a)},
iJ(a){var t=this
if(a==null)return A.aX(t)
return A.kg(v.typeUniverse,A.kf(a,t),t)},
iL(a){if(a==null)return!0
return this.x.b(a)},
j3(a){var t,s=this
if(a==null)return A.aX(s)
t=s.f
if(a instanceof A.p)return!!a[t]
return!!J.aA(a)[t]},
iW(a){var t,s=this
if(a==null)return A.aX(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.p)return!!a[t]
return!!J.aA(a)[t]},
iV(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.p)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
eX(a){if(typeof a=="object"){if(a instanceof A.p)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
iI(a){var t=this
if(a==null){if(A.aX(t))return a}else if(t.b(a))return a
throw A.E(A.eP(a,t),new Error())},
iK(a){var t=this
if(a==null||t.b(a))return a
throw A.E(A.eP(a,t),new Error())},
eP(a,b){return new A.bx("TypeError: "+A.ev(a,A.M(b,null)))},
ev(a,b){return A.bS(a)+": type '"+A.M(A.dR(a),null)+"' is not a subtype of type '"+b+"'"},
Q(a,b){return new A.bx("TypeError: "+A.ev(a,b))},
iT(a){var t=this
return t.x.b(a)||A.dI(v.typeUniverse,t).b(a)},
iZ(a){return a!=null},
dN(a){if(a!=null)return a
throw A.E(A.Q(a,"Object"),new Error())},
j4(a){return!0},
iz(a){return a},
eY(a){return!1},
dQ(a){return!0===a||!1===a},
ir(a){if(!0===a)return!0
if(!1===a)return!1
throw A.E(A.Q(a,"bool"),new Error())},
is(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.E(A.Q(a,"bool?"),new Error())},
it(a){if(typeof a=="number")return a
throw A.E(A.Q(a,"double"),new Error())},
iu(a){if(typeof a=="number")return a
if(a==null)return a
throw A.E(A.Q(a,"double?"),new Error())},
eW(a){return typeof a=="number"&&Math.floor(a)===a},
R(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.E(A.Q(a,"int"),new Error())},
iv(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.E(A.Q(a,"int?"),new Error())},
iY(a){return typeof a=="number"},
eK(a){if(typeof a=="number")return a
throw A.E(A.Q(a,"num"),new Error())},
eL(a){if(typeof a=="number")return a
if(a==null)return a
throw A.E(A.Q(a,"num?"),new Error())},
j2(a){return typeof a=="string"},
Y(a){if(typeof a=="string")return a
throw A.E(A.Q(a,"String"),new Error())},
iy(a){if(typeof a=="string")return a
if(a==null)return a
throw A.E(A.Q(a,"String?"),new Error())},
iw(a){if(A.eX(a))return a
throw A.E(A.Q(a,"JSObject"),new Error())},
ix(a){if(a==null)return a
if(A.eX(a))return a
throw A.E(A.Q(a,"JSObject?"),new Error())},
f5(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.M(a[r],b)
return t},
jO(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.f5(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.M(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
eR(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.i([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.c.l(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.b(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.M(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.M(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.M(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.M(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.M(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
M(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.M(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.M(a.x,b)+">"
if(m===8){q=A.jY(a.x)
p=a.y
return p.length>0?q+("<"+A.f5(p,b)+">"):q}if(m===10)return A.jO(a,b)
if(m===11)return A.eR(a,b,null)
if(m===12)return A.eR(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.b(b,o)
return b[o]}return"?"},
jY(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
iq(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
ip(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.d2(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bA(a,5,"#")
r=A.d3(t)
for(q=0;q<t;++q)r[q]=s
p=A.bz(a,b,r)
o[b]=p
return p}else return n},
io(a,b){return A.eH(a.tR,b)},
im(a,b){return A.eH(a.eT,b)},
d2(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.eA(A.ey(a,null,b,!1))
s.set(b,t)
return t},
bB(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.eA(A.ey(a,b,c,!0))
r.set(c,s)
return s},
eG(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.dL(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
aj(a,b){b.a=A.iM
b.b=A.iN
return b},
bA(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.X(null,null)
t.w=b
t.as=c
s=A.aj(a,t)
a.eC.set(c,s)
return s},
eE(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.ik(a,b,s,c)
a.eC.set(s,t)
return t},
ik(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.aB(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.aX(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.X(null,null)
r.w=6
r.x=b
r.as=c
return A.aj(a,r)},
eD(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.ii(a,b,s,c)
a.eC.set(s,t)
return t},
ii(a,b,c,d){var t,s
if(d){t=b.w
if(A.aB(b)||b===u.K)return b
else if(t===1)return A.bz(a,"ed",[b])
else if(b===u.P||b===u.T)return u.O}s=new A.X(null,null)
s.w=7
s.x=b
s.as=c
return A.aj(a,s)},
il(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.X(null,null)
t.w=13
t.x=b
t.as=r
s=A.aj(a,t)
a.eC.set(r,s)
return s},
by(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
ih(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bz(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.by(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.X(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.aj(a,s)
a.eC.set(q,r)
return r},
dL(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.by(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.X(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.aj(a,p)
a.eC.set(r,o)
return o},
eF(a,b,c){var t,s,r="+"+(b+"("+A.by(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.X(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.aj(a,t)
a.eC.set(r,s)
return s},
eC(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.by(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.by(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.ih(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.X(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.aj(a,q)
a.eC.set(s,p)
return p},
dM(a,b,c,d){var t,s=b.as+("<"+A.by(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.ij(a,b,c,s,d)
a.eC.set(s,t)
return t},
ij(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.d3(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.ay(a,b,s,0)
n=A.aW(a,c,s,0)
return A.dM(a,o,n,c!==n)}}m=new A.X(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.aj(a,m)},
ey(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
eA(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.ia(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.ez(a,s,m,l,!1)
else if(r===46)s=A.ez(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.ax(a.u,a.e,l.pop()))
break
case 94:l.push(A.il(a.u,l.pop()))
break
case 35:l.push(A.bA(a.u,5,"#"))
break
case 64:l.push(A.bA(a.u,2,"@"))
break
case 126:l.push(A.bA(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.ic(a,l)
break
case 38:A.ib(a,l)
break
case 63:q=a.u
l.push(A.eE(q,A.ax(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.eD(q,A.ax(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.i9(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.eB(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.ie(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.ax(a.u,a.e,n)},
ia(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
ez(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.iq(t,p.x)[q]
if(o==null)A.aZ('No "'+q+'" in "'+A.hS(p)+'"')
d.push(A.bB(t,p,o))}else d.push(q)
return n},
ic(a,b){var t,s=a.u,r=A.ex(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bz(s,q,r))
else{t=A.ax(s,a.e,q)
switch(t.w){case 11:b.push(A.dM(s,t,r,a.n))
break
default:b.push(A.dL(s,t,r))
break}}},
i9(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.ex(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.ax(q,a.e,p)
r=new A.cd()
r.a=t
r.b=o
r.c=n
b.push(A.eC(q,s,r))
return
case-4:b.push(A.eF(q,b.pop(),t))
return
default:throw A.c(A.bH("Unexpected state under `()`: "+A.r(p)))}},
ib(a,b){var t=b.pop()
if(0===t){b.push(A.bA(a.u,1,"0&"))
return}if(1===t){b.push(A.bA(a.u,4,"1&"))
return}throw A.c(A.bH("Unexpected extended operation "+A.r(t)))},
ex(a,b){var t=b.splice(a.p)
A.eB(a.u,a.e,t)
a.p=b.pop()
return t},
ax(a,b,c){if(typeof c=="string")return A.bz(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.id(a,b,c)}else return c},
eB(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.ax(a,b,c[t])},
ie(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.ax(a,b,c[t])},
id(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.c(A.bH("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.c(A.bH("Bad index "+c+" for "+b.j(0)))},
kg(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.B(a,b,null,c,null)
s.set(c,t)}return t},
B(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.aB(d))return!0
t=b.w
if(t===4)return!0
if(A.aB(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.B(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.B(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.B(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.B(a,b.x,c,d,e))return!1
return A.B(a,A.dI(a,b),c,d,e)}if(t===6)return A.B(a,q,c,d,e)&&A.B(a,b.x,c,d,e)
if(r===7){if(A.B(a,b,c,d.x,e))return!0
return A.B(a,b,c,A.dI(a,d),e)}if(r===6)return A.B(a,b,c,q,e)||A.B(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.M)return!0
if(r===12){if(b===u.L)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.B(a,k,c,j,e)||!A.B(a,j,e,k,c))return!1}return A.eV(a,b.x,c,d.x,e)}if(r===11){if(b===u.L)return!0
if(q)return!1
return A.eV(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.iU(a,b,c,d,e)}if(p&&r===10)return A.j_(a,b,c,d,e)
return!1},
eV(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.B(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.B(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.B(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.B(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.B(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
iU(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.bB(a,b,s[p])
return A.eJ(a,q,null,c,d.y,e)}return A.eJ(a,b.y,null,c,d.y,e)},
eJ(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.B(a,b[t],d,e[t],f))return!1
return!0},
j_(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.B(a,s[t],c,r[t],e))return!1
return!0},
aX(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.aB(a))if(t!==6)s=t===7&&A.aX(a.x)
return s},
aB(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
eH(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
d3(a){return a>0?new Array(a):v.typeUniverse.sEA},
X:function X(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
cd:function cd(){this.c=this.b=this.a=null},
ci:function ci(a){this.a=a},
cc:function cc(){},
bx:function bx(a){this.a=a},
hI(a,b){return new A.V(a.i("@<0>").V(b).i("V<1,2>"))},
dC(a,b,c){return b.i("@<0>").V(c).i("dB<1,2>").a(A.k8(a,new A.V(b.i("@<0>").V(c).i("V<1,2>"))))},
aM(a,b){return new A.V(a.i("@<0>").V(b).i("V<1,2>"))},
hJ(a){return new A.av(a.i("av<0>"))},
cF(a){return new A.av(a.i("av<0>"))},
dK(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
ai(a,b,c){var t=new A.aw(a,b,c.i("aw<0>"))
t.c=a.e
return t},
dD(a,b){var t=A.hJ(b)
t.W(0,a)
return t},
dF(a){var t,s
if(A.dU(a))return"{...}"
t=new A.aS("")
try{s={}
B.c.l($.N,a)
t.a+="{"
s.a=!0
a.Y(0,new A.cH(s,t))
t.a+="}"}finally{if(0>=$.N.length)return A.b($.N,-1)
$.N.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
av:function av(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
ce:function ce(a){this.a=a
this.b=null},
aw:function aw(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
aN:function aN(){},
cH:function cH(a,b){this.a=a
this.b=b},
a8:function a8(){},
bw:function bw(){},
eh(a,b,c){return new A.bc(a,b)},
iE(a){return a.a2()},
i7(a,b){return new A.cW(a,[],A.k4())},
i8(a,b,c){var t,s=new A.aS(""),r=A.i7(s,b)
r.a3(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
bP:function bP(){},
bR:function bR(){},
bc:function bc(a,b){this.a=a
this.b=b},
c_:function c_(a,b){this.a=a
this.b=b},
cC:function cC(){},
cD:function cD(a){this.b=a},
cX:function cX(){},
cY:function cY(a,b){this.a=a
this.b=b},
cW:function cW(a,b,c){this.c=a
this.a=b
this.b=c},
f9(a){var t=A.hO(a)
if(t!=null)return t
throw A.c(A.ec("Invalid double",a))},
cG(a,b,c,d){var t,s=J.hE(a,d)
if(a!==0&&b!=null)for(t=0;t<a;++t)s[t]=b
return s},
hK(a,b,c){var t,s,r=A.i([],c.i("k<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.O)(a),++s)B.c.l(r,c.a(a[s]))
r.$flags=1
return r},
ah(a,b){var t,s
if(Array.isArray(a))return A.i(a.slice(0),b.i("k<0>"))
t=A.i([],b.i("k<0>"))
for(s=J.dn(a);s.k();)B.c.l(t,s.gn())
return t},
dE(a,b){var t=A.hK(a,!1,b)
t.$flags=3
return t},
el(a){return new A.aK(a,A.eg(a,!1,!0,!1,!1,""))},
ep(a,b,c){var t=J.dn(b)
if(!t.k())return a
if(c.length===0){do a+=A.r(t.gn())
while(t.k())}else{a+=A.r(t.gn())
while(t.k())a=a+c+A.r(t.gn())}return a},
bS(a){if(typeof a=="number"||A.dQ(a)||a==null)return J.bD(a)
if(typeof a=="string")return JSON.stringify(a)
return A.ej(a)},
bH(a){return new A.bG(a)},
dp(a){return new A.T(!1,null,null,a)},
bF(a,b,c){return new A.T(!0,a,b,c)},
ek(a,b){return new A.bk(null,null,!0,a,b,"Value not in range")},
a_(a,b,c,d,e){return new A.bk(b,c,!0,a,d,"Invalid value")},
hQ(a,b,c){if(0>a||a>c)throw A.c(A.a_(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.a_(b,a,c,"end",null))
return b}return c},
dH(a,b){return a},
dw(a,b,c,d){return new A.bT(b,!0,a,d,"Index out of range")},
es(a){return new A.bt(a)},
dJ(a){return new A.bp(a)},
U(a){return new A.bQ(a)},
ec(a,b){return new A.cy(a,b)},
hD(a,b,c){var t,s
if(A.dU(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.i([],u.s)
B.c.l($.N,a)
try{A.j5(a,t)}finally{if(0>=$.N.length)return A.b($.N,-1)
$.N.pop()}s=A.ep(b,u.W.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
ee(a,b,c){var t,s
if(A.dU(a))return b+"..."+c
t=new A.aS(b)
B.c.l($.N,a)
try{s=t
s.a=A.ep(s.a,a,", ")}finally{if(0>=$.N.length)return A.b($.N,-1)
$.N.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
j5(a,b){var t,s,r,q,p,o,n,m=a.gq(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.k())return
t=A.r(m.gn())
B.c.l(b,t)
l+=t.length+2;++k}if(!m.k()){if(k<=5)return
if(0>=b.length)return A.b(b,-1)
s=b.pop()
if(0>=b.length)return A.b(b,-1)
r=b.pop()}else{q=m.gn();++k
if(!m.k()){if(k<=4){B.c.l(b,A.r(q))
return}s=A.r(q)
if(0>=b.length)return A.b(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gn();++k
for(;m.k();q=p,p=o){o=m.gn();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.b(b,-1)
l-=b.pop().length+2;--k}B.c.l(b,"...")
return}}r=A.r(q)
s=A.r(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.b(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.c.l(b,n)
B.c.l(b,r)
B.c.l(b,s)},
a6(a,b,c,d,e,f){var t
if(B.d===c){t=J.t(a)
b=J.t(b)
return A.br(A.A(A.A($.b_(),t),b))}if(B.d===d){t=J.t(a)
b=J.t(b)
c=J.t(c)
return A.br(A.A(A.A(A.A($.b_(),t),b),c))}if(B.d===e){t=J.t(a)
b=J.t(b)
c=J.t(c)
d=J.t(d)
return A.br(A.A(A.A(A.A(A.A($.b_(),t),b),c),d))}if(B.d===f){t=J.t(a)
b=J.t(b)
c=J.t(c)
d=J.t(d)
e=J.t(e)
return A.br(A.A(A.A(A.A(A.A(A.A($.b_(),t),b),c),d),e))}t=J.t(a)
b=J.t(b)
c=J.t(c)
d=J.t(d)
e=J.t(e)
f=J.t(f)
f=A.br(A.A(A.A(A.A(A.A(A.A(A.A($.b_(),t),b),c),d),e),f))
return f},
dG(a){var t,s,r=$.b_()
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.O)(a),++s)r=A.A(r,J.t(a[s]))
return A.br(r)},
cU:function cU(){},
w:function w(){},
bG:function bG(a){this.a=a},
bs:function bs(){},
T:function T(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
bk:function bk(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bT:function bT(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bt:function bt(a){this.a=a},
bp:function bp(a){this.a=a},
bQ:function bQ(a){this.a=a},
c1:function c1(){},
bo:function bo(){},
cV:function cV(a){this.a=a},
cy:function cy(a,b){this.a=a
this.b=b},
e:function e(){},
aq:function aq(a,b,c){this.a=a
this.b=b
this.$ti=c},
bh:function bh(){},
p:function p(){},
aQ:function aQ(a){var _=this
_.a=a
_.c=_.b=0
_.d=-1},
aS:function aS(a){this.a=a},
e3(c8){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=c8.a,b4=b3.c,b5=b3.a===b3.b,b6=b3.d,b7=A.k7(b6,A.e9(b4)),b8=A.dq(b3),b9=b4===B.J,c0=b9||b4===B.X,c1=!b5,c2=c1&&A.fF(b3),c3=b4===B.n,c4=b4!==B.C,c5=!c4||b4===B.y,c6=c3&&b5,c7=c3&&c1
if(c3||c5){t=b3.e
s=new A.d(t,A.a(t).i("d<2>"))
r=s.h(0,B.f)
q=s.h(0,B.i)
p=r&&q}else p=!1
o=c7&&A.fG(b3)
t=b3.e
n=new A.d(t,A.a(t).i("d<2>")).h(0,B.f)
m=b6.h(0,B.B)||b6.h(0,B.q)
l=n&&m
k=A.aF(b4)
j=A.P(b4)
i=A.du(b4)
h=A.fO(b3)
g=A.fU(b3,b5)
f=A.fL(b3)
e=A.fK(b3)
d=A.fM(b3,b5)
c=A.fR(b3,b5)
b=A.fP(b3)
a=A.fN(b3)
a0=A.dq(b3)
a1=A.fI(b3,b5)
a2=A.fT(b3,b5)
a3=!1
if(b5)if(b4===B.t||b4===B.D||b4===B.E||b4===B.a0){a3=b7.a
a3=a3[1]===0&&a3[2]===0}a4=A.fV(b3,b5)
c4=b4===B.N||b4===B.aa||b4===B.a1||!c4||b4===B.y||b4===B.ai||b4===B.ab||b4===B.V||b4===B.W
a5=A.e4(b3,B.ca,B.v,B.T,B.e,B.n)
A.e4(b3,B.aS,B.I,B.a_,B.e,B.n)
a6=A.fJ(b3)
a7=A.fQ(b3)
b6=b6.a
a8=b7.a
a9=a8[1]
b0=l?a9+1:a9
b1=A.fS(b3,b5,l)
b2=a8[2]
a8=a8[0]>0&&a9===0&&b2===0
return new A.a2(b5,k,j===B.r,b9,c0,i,h,g,f,e,d,b4===B.a3,c,b,a,a0===2,a1,a2,a3,a4,c4,c3,c5,c6,c7,p,o,a5,a6,a7,c1,b8,c2,b8<=2,b6,b0,b1,b7,a9>0,b2+a9>0,a8,A.aC(b3.f)-t.a)},
e4(a,b,c,d,e,f){var t,s,r,q
if(a.c!==f)return!1
t=a.d
if(!t.h(0,c))return!1
for(t=A.ai(t,t.r,A.a(t).c),s=t.$ti.c;t.k();){r=t.d
if(r==null)r=s.a(r)
if(r!==c&&!b.h(0,r))return!1}t=a.e
q=new A.d(t,A.a(t).i("d<2>"))
return q.h(0,B.l)&&q.h(0,d)&&q.h(0,B.f)&&q.h(0,e)&&q.h(0,B.i)},
fQ(a){var t,s,r
if(a.c!==B.n)return!1
t=a.d
if(t.a!==1||!t.h(0,B.v))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
if(!s.h(0,B.l)||!s.h(0,B.f)||!s.h(0,B.i)||s.h(0,B.e))return!1
r=A.al(a.b,a.a)
if(r!==1)return!1
return t.p(0,r)===B.T},
fJ(a){var t,s,r,q=a.c
if(q!==B.C&&q!==B.y)return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
r=s.h(0,B.x)||s.h(0,B.u)
return s.h(0,B.l)&&s.h(0,B.f)&&r&&s.h(0,B.i)},
fO(a){var t,s
if(a.c!==B.D)return!1
t=a.d
if(t.a!==1)return!1
if(!t.h(0,B.o))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.m)&&s.h(0,B.e)&&s.h(0,B.Y)},
fU(a,b){var t,s=!0
if(b)if(a.c===B.M){s=a.d
s=s.a!==1||!s.h(0,B.B)}if(s)return!1
s=a.e
t=new A.d(s,A.a(s).i("d<2>"))
return t.h(0,B.l)&&t.h(0,B.m)&&t.h(0,B.i)&&t.h(0,B.ad)},
fL(a){var t,s
if(a.c===B.E){t=a.d
t=t.a!==1||!t.h(0,B.A)}else t=!0
if(t)return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.f)&&s.h(0,B.e)&&s.h(0,B.O)&&s.h(0,B.af)},
fK(a){var t,s,r,q=a.c,p=q===B.t
if(!p&&q!==B.D)return!1
if(a.d.az(0,new A.cl(q)))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
r=p?s.h(0,B.f):s.h(0,B.m)
return s.h(0,B.l)&&r&&s.h(0,B.e)},
fM(a,b){var t,s
if(b)return!1
if(a.c!==B.t)return!1
if(A.dq(a)>2)return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.f)&&s.h(0,B.e)},
fW(a,b){if(b===B.t&&a===B.B)return!0
return a===B.v||a===B.I||a===B.R||a===B.o||a===B.w},
fR(a,b){var t
if(!A.aF(a.c))return!1
if(b)return!1
t=a.e
return!new A.d(t,A.a(t).i("d<2>")).h(0,B.e)},
fP(a){var t,s,r,q,p,o
if(A.P(a.c)!==B.r)return!1
t=a.a
s=a.b
if(t===s)return!1
r=a.d
if(r.a!==1||!r.h(0,B.k))return!1
if(A.al(s,t)!==2)return!1
t=a.e
q=new A.d(t,A.a(t).i("d<2>"))
p=q.h(0,B.f)||q.h(0,B.m)||q.h(0,B.K)||q.h(0,B.L)
o=q.h(0,B.i)||q.h(0,B.z)
return q.h(0,B.l)&&p&&q.h(0,B.e)&&o},
fN(a){var t,s,r,q
if(a.c!==B.M)return!1
t=a.a
s=a.b
if(t===s)return!1
r=a.d
if(r.a!==1||!r.h(0,B.B))return!1
if(A.al(s,t)!==5)return!1
t=a.e
q=new A.d(t,A.a(t).i("d<2>"))
return q.h(0,B.l)&&q.h(0,B.m)&&q.h(0,B.e)&&q.h(0,B.i)},
fI(a,b){if(!b)return!1
if(a.c!==B.ab)return!1
return a.d.h(0,B.w)},
fT(a,b){var t,s,r,q
if(!b)return!1
t=a.c
s=t===B.aa
if(!s&&t!==B.a1)return!1
r=a.e
q=new A.d(r,A.a(r).i("d<2>"))
return(s?q.h(0,B.K):q.h(0,B.L))&&q.h(0,B.i)},
fV(a,b){var t,s,r=a.c
if(r===B.aj||r===B.ak)return!0
if(A.P(r)===B.r&&!b){t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
if(!(s.h(0,B.e)||s.h(0,B.x)||s.h(0,B.u)))return!0}return!1},
fS(a,b,c){var t
if(b)return!1
t=a.c
if(t===B.n||t===B.C||t===B.y)return!1
return c},
fG(a){var t,s,r,q
if(a.c!==B.n)return!1
t=a.a
s=a.b
if(t===s)return!1
r=A.fH(a.e.p(0,A.al(s,t)))
for(t=a.d,t=A.ai(t,t.r,A.a(t).c),s=t.$ti.c;t.k();){q=t.d
if(q==null)q=s.a(q)
if(q===r)continue
if(q===B.v||q===B.I||q===B.o||q===B.w)return!0}return!1},
fH(a){var t
A:{if(B.T===a){t=B.v
break A}if(B.a_===a){t=B.I
break A}if(B.Y===a){t=B.o
break A}if(B.am===a){t=B.w
break A}if(B.ao===a){t=B.k
break A}if(B.ac===a){t=B.q
break A}if(B.ae===a){t=B.p
break A}if(B.af===a){t=B.A
break A}if(B.aN===a){t=B.R
break A}if(B.ap===a){t=B.R
break A}if(B.ad===a){t=B.B
break A}if(B.an===a){t=B.a9
break A}t=null
break A}return t},
fF(a){var t=a.e.p(0,A.al(a.b,a.a))
if(t==null)return!1
return!(t===B.l||t===B.f||t===B.m||t===B.e||t===B.x||t===B.u||t===B.O||t===B.i||t===B.z||t===B.Z)},
dq(a){var t=A.al(a.b,a.a)
if(t===0)return 0
if(t===3||t===4)return 1
if(t===7)return 2
if(t===10||t===11)return 3
return 4},
a2:function a2(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q
_.CW=r
_.cx=s
_.cy=t
_.db=a0
_.dx=a1
_.dy=a2
_.fx=a3
_.fy=a4
_.go=a5
_.id=a6
_.k1=a7
_.k3=a8
_.k4=a9
_.ok=b0
_.p1=b1
_.p2=b2
_.p3=b3
_.p4=b4
_.R8=b5
_.RG=b6
_.rx=b7
_.to=b8
_.x1=b9
_.x2=c0
_.xr=c1},
cl:function cl(a){this.a=a},
h9(a,b,c,d){var t,s,r,q,p,o,n=A.a6(A.dG(d.a),d.b,B.d,B.d,B.d,B.d),m=A.a6((a.a|a.b<<12)>>>0,n,b,c,B.d,B.d)
n=$.fh()
t=n.p(0,m)
if(t!=null){n.aB(0,m)
n.u(0,m,t)
return t}s=A.h_(a,b,!1,d)
r=A.eq(s,0,A.f6(c,"count",u.S),A.G(s).c)
q=r.$ti
p=q.i("L<F.E,I>")
r=A.ah(new A.L(r,q.i("I(F.E)").a(new A.co()),p),p.i("F.E"))
r.$flags=1
o=r
n.u(0,m,o)
if(n.a>512)n.aB(0,new A.a4(n,A.a(n).i("a4<1>")).gT(0))
return o},
h_(a,b,c,d){var t,s,r,q,p,o,n,m,l,k,j,i=a.a
if(i===0)return B.c0
t=A.i([],u.r)
for(s=a.b,r=0;r<12;++r){if((i&B.a.K(1,r))>>>0===0)continue
q=A.h6(i,r)
p=B.a.m(s-r,12)
for(o=$.dY(),n=0;n<26;++n){m=o[n]
l=A.h7(p,b,null,q,r,m)
if(l==null)continue
k=m.a
j=l.b
B.c.l(t,new A.at(new A.I(new A.bJ(r,s,k,j,A.hw(j,k,q),q),l.a)))}}return A.hd(t,new A.cm(),b.a,d,u.o)},
h7(b8,b9,c0,c1,c2,c3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6=null,b7=new A.cn(c0)
if((c1&1)===0)return b6
t=c3.b|1
s=c3.c
r=c3.d
if(c3.e&&c1!==(t|s))return b6
q=t&~c1
p=t&c1
o=s&c1
n=A.h2(b8,c1,c3)
m=r&c1&~n
l=A.aC(q)
if(l>1)return b6
k=A.aC(p)
j=A.aC(o)
i=A.aC(m)
h=t|s
g=(c1&~(h|r)|n)>>>0
f=c3.a
e=A.P(f)===B.r
d=A.cF(u.G)
if((g&2)!==0)d.l(0,e||A.aF(f)?B.v:B.b6)
if((g&8)!==0){if(!e)c=!(f===B.t||f===B.E||f===B.a5)
else c=!0
d.l(0,c?B.I:B.R)}if((g&64)!==0)d.l(0,B.o)
if((g&256)!==0)d.l(0,B.w)
b=(g&14)!==0
if((g&4)!==0)d.l(0,e?B.k:B.A)
if((g&32)!==0)d.l(0,e&&b?B.q:B.B)
if((g&512)!==0)d.l(0,e&&b?B.p:B.a9)
a=A.e5(d,f)&&(g&330)!==0
c=A.aC(g)
a0=c-(a?1:0)
if(A.h1(d,f))return b6
a1=k*4
b7.$4$detail$intervals("required tones",a1,"count="+k,p)
a2=-l*6
b7.$4$detail$intervals("missing required",a2,"count="+l,q)
a3=j*1.5
b7.$4$detail$intervals("optional tones",a3,"count="+j,o)
a4=-i*3
b7.$4$detail$intervals("penalty tones",a4,"count="+i,m)
a5=-a0*0.5
b7.$4$detail$intervals("extras",a5,"count="+a0,g)
a6=B.a.P(1,b8)
if((h&a6)!==0)a7=1
else if((g&a6)>>>0!==0)a7=A.P(f)===B.r&&d.a!==0?0.75:0.25
else a7=-0.25
a8=a1+a2+a3+a4+a5+a7
b7.$3$detail("bass fit",a7,"interval="+b8)
if((f===B.a3||f===B.N)&&b8===8){a8-=3
b7.$2("m#5 bass",-3)}if(A.h4(b8,f)){a8-=2
b7.$2("sus-tone bass",-2)}A:{c=B.J===f
a9=0.3
if(c)break A
if(A.P(f)!==B.r&&!A.aF(f))break A
a9=0.6
break A}if(A.e5(d,f)){a8-=a9
B:{if(c){c="dim7 softened"
break B}if(A.P(f)!==B.r&&!A.aF(f)){c="triad softened"
break B}c=b6
break B}b7.$3$detail("alterations penalty",-a9,c)}b0=A.fZ(b8,d,f,c1)
if(b0!==0){a8+=b0
b7.$2("dominant stack",b0)}b1=A.h0(b8,d,f,c1)
if(b1!==0){a8+=b1
b7.$2("fifthless extension stack",b1)}b2=A.fY(d,f,c1)
if(b2!==0){a8+=b2
b7.$2("complete b13 dominant",b2)}b3=A.fX(b8,d,f,c1)
if(b3!==0){a8+=b3
b7.$2("add9 bass triad",b3)}if(A.h3(f,c1)){a8-=0.6
b7.$3$detail("sixNo5",-0.6,"pitchClasses="+A.aC(c1))}b4=k>0?Math.sqrt(k):1
b5=a8/b4
if(c0!=null)b7.$3$detail("normalize",0,"raw="+B.F.N(a8,2)+" denom="+B.F.N(b4,2)+" => "+B.F.N(b5,2))
return new A.d1(b5,d)},
e5(a,b){var t=!0
if(!a.h(0,B.v))if(!a.h(0,B.I))t=a.h(0,B.o)&&!A.e9(b)||a.h(0,B.w)
return t},
h2(a,b,c){var t=c.a
if(A.h8(a,b)&&A.h5(t,b))return 8
if(!(t===B.n||t===B.C||t===B.y))return 0
if(!((b&16)!==0&&(b&1024)!==0))return 0
if((b&8)===0)return 0
return 8},
h8(a,b){var t,s
if(a===0)return!0
t=a===4||a===7
s=(b&128)!==0
return t&&s},
h5(a,b){if(!(a===B.t||a===B.E||a===B.a5))return!1
return(b&16)!==0&&(b&8)!==0},
h3(a,b){if(A.aC(b)!==3)return!1
if(!(a===B.E||a===B.a0))return!1
return(b&128)===0},
h4(a,b){switch(b.a){case 6:case 12:case 17:return a===2
case 7:case 13:case 18:return a===5
default:return!1}},
h1(a,b){if(!(b===B.C||b===B.V))return!1
return a.h(0,B.p)||a.h(0,B.a9)},
fZ(a,b,c,d){var t,s
if(c!==B.n)return 0
if(!b.h(0,B.k))return 0
if(!b.h(0,B.o))return 0
t=b.h(0,B.p)
s=b.h(0,B.w)
if(!t&&!s)return a===0?0.8:0
if(t&&!s)return a===0?2.1:0
if(s&&(d&128)===0)return 0
return 2.1},
h0(a,b,c,d){if(a!==0)return 0
if(c!==B.a2&&c!==B.n)return 0
if(!b.h(0,B.k))return 0
if(b.h(0,B.w))return 0
if(!(b.h(0,B.o)||b.h(0,B.p)))return 0
if((d&128)!==0)return 0
return 2.4},
fY(a,b,c){if(b!==B.n)return 0
if(a.a!==1||!a.h(0,B.w))return 0
return(c&1)!==0&&(c&16)!==0&&(c&128)!==0&&(c&1024)!==0?0.15:0},
fX(a,b,c,d){var t,s=c===B.t
if(!(s||c===B.D))return 0
if(a!==2)return 0
if(b.a!==1||!b.h(0,B.A))return 0
t=(d&128)===0
if((d&B.a.K(1,s?4:3))>>>0===0||t)return 0
return 3.2},
h6(a,b){var t,s,r
for(t=0,s=0;s<12;++s){if((a&B.a.K(1,s))>>>0===0)continue
r=B.a.m(s-b,12)
t=(t|B.a.P(1,r))>>>0}return t},
cP:function cP(a,b,c){this.a=a
this.b=b
this.c=c},
co:function co(){},
cm:function cm(){},
cn:function cn(a){this.a=a},
at:function at(a){this.a=a},
d1:function d1(a,b){this.a=a
this.b=b},
hd(a,b,c,a0,a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=a.length
if(d<=1){t=A.ah(a,a1)
return t}t=A.i([],u.B)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.O)(a),++r)t.push(b.$1(a[r]))
s=J.cz(d,u.S)
for(q=0;q<d;++q)s[q]=q
B.c.R(s,new A.cp(t))
p=u.v
o=J.cz(d,p)
for(n=u.y,m=0;m<d;++m)o[m]=A.cG(d,!1,!1,n)
l=J.cz(d,p)
for(k=0;k<d;++k)l[k]=A.cG(d,!1,!1,n)
for(q=0;q<d;++q)for(j=0;j<d;++j){if(q===j)continue
p=t.length
if(!(q<p))return A.b(t,q)
n=t[q]
if(!(j<p))return A.b(t,j)
i=A.ha(n,t[j],c,a0)
if(i.a<0){if(!(q<o.length))return A.b(o,q)
B.c.u(o[q],j,!0)
if(i.d){if(!(q<l.length))return A.b(l,q)
B.c.u(l[q],j,!0)}}}h=A.i(s.slice(0),A.G(s))
g=A.i([],a1.i("k<0>"))
for(f=h.$flags|0;h.length!==0;){e=A.hb(h,o,l)
if(!(e>=0&&e<h.length))return A.b(h,e)
t=h[e]
if(!(t>=0&&t<a.length))return A.b(a,t)
B.c.l(g,a[t])
f&1&&A.ck(h,"removeAt",1)
t=h.length
if(e>=t)A.aZ(A.ek(e,null))
h.splice(e,1)[0]}return g},
hb(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i,h=a.length
for(t=b.length,s=0;s<h;++s){r=a[s]
p=0
for(;;){if(!(p<h)){q=!1
break}A:{if(s===p)break A
o=a[p]
if(!(o>=0&&o<t))return A.b(b,o)
o=b[o]
if(!(r>=0&&r<o.length))return A.b(o,r)
if(o[r]){q=!0
break}}++p}if(!q)return s}for(o=c.length,n=-1,m=-1,s=0;s<h;++s){r=a[s]
p=0
for(;;){if(!(p<h)){l=!1
break}B:{if(s===p)break B
k=a[p]
if(!(k>=0&&k<o))return A.b(c,k)
k=c[k]
if(!(r>=0&&r<k.length))return A.b(k,r)
if(k[r]){l=!0
break}}++p}if(l)continue
for(j=0,p=0;p<h;++p){if(s===p)continue
if(!(r>=0&&r<t))return A.b(b,r)
k=b[r]
i=a[p]
if(!(i>=0&&i<k.length))return A.b(k,i)
if(k[i])++j}if(j>m){m=j
n=s}}return n===-1?0:n},
ha(a,b,c,d){var t,s,r,q,p=b.b-a.b,o=A.e3(a),n=A.e3(b)
for(t=$.fw(),s=0;s<18;++s){r=t[s].b.$5(a,b,o,n,c)
if(r!=null&&r!==0)return new A.ar(r,!0)}if(Math.abs(p)>0.2)return new A.ar(p>0?1:-1,!1)
q=A.hc(a,b,d)
if(q!==0)return new A.ar(q,!1)
for(t=$.fx(),s=0;s<27;++s){r=t[s].b.$5(a,b,o,n,c)
if(r!=null&&r!==0)return new A.ar(r,!1)}return new A.ar(B.a.A(a.a.a,b.a.a),!1)},
hc(a,b,c){var t=A.eu(a.a,c)
if(t===A.eu(b.a,c))return 0
return t?-1:1},
ar:function ar(a,b){this.a=a
this.d=b},
cp:function cp(a){this.a=a},
v(a,b,c){var t=a.c
return new A.b5(a.a,a.b&4294967294&~t,t,b,c)},
b5:function b5(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
kl(a,b,c,d,e){var t,s,r,q,p,o=null
if(Math.abs(a.b-b.b)>0.15)return o
if(c.xr!==d.xr)return o
if(c.p4!==d.p4)return o
if(c.R8!==d.R8)return o
t=A.eO(a.a)
s=A.eO(b.a)
if(t===s)return o
r=t>s
q=r?t:s
p=r?s:t
if(q<100)return o
if(p>0&&q/p<2)return o
return r?-1:1},
eO(a){var t=B.c5.p(0,A.iD(a))
return t==null?0:t},
iD(a){var t,s=a.d
if(s.a===0)return a.c.b
t=A.ah(s,A.a(s).c)
B.c.R(t,new A.d6())
s=A.G(t)
return a.c.b+"|"+new A.L(t,s.i("h(1)").a(new A.d7()),s.i("L<1,h>")).J(0,",")},
d6:function d6(){},
d7:function d7(){},
f(a,b){return new A.bg(a,b)},
jn(a,b,c,d,e){var t,s=null,r=a.a,q=A.f1(r),p=b.a,o=A.f1(p),n=A.f0(r),m=A.f0(p)
if(!(q&&m))t=!(o&&n)
else t=!1
if(t)return s
if(A.al(r.a,p.a)!==6)return s
r=c.p1
p=d.p1
if(r===p)return s
if(Math.abs(a.b-b.b)>0.3)return s
return r<p?-1:1},
f1(a){var t
if(a.c===B.C){t=a.d
t=t.a===2&&t.h(0,B.v)&&t.h(0,B.k)}else t=!1
return t},
f0(a){var t
if(a.c===B.n){t=a.d
t=t.a===2&&t.h(0,B.o)&&t.h(0,B.w)}else t=!1
return t},
jF(a,b,c,d,e){var t,s,r,q,p=c.w
if(p===d.w)return null
t=p?b:a
s=!(p?d:c).a
r=s&&t.a.c===B.a1
q=s&&t.a.c===B.al
if(!r&&!q)return null
if((p?a:b).b+1.3<t.b)return null
return p?-1:1},
jf(a,b,c,d,e){var t,s,r,q=c.x
if(q===d.x)return null
t=q?b:a
s=!0
if(!(q?d:c).a){r=t.a
if(r.c===B.N){s=r.d
s=s.a!==1||!s.h(0,B.B)}}if(s)return null
if((q?a:b).b+0.3<t.b)return null
return q?-1:1},
j6(a,b,c,d,e){var t,s,r=c.b
if(r===d.b)return null
t=r?c:d
s=r?d:c
if(t.a&&!s.a&&s.p4===0)return r?-1:1
return null},
jk(a,b,c,d,e){var t,s,r=c.as,q=d.as
if(r===q)return null
t=c.y
s=d.y
if(r&&s)return 1
if(q&&t)return-1
return null},
jc(a,b,c,d,e){var t,s,r=A.eT(a.a)
if(r===A.eT(b.a))return null
t=r?b:a
s=r?d:c
if(!A.j1(t.a,s))return null
if((r?a:b).b+0.55<t.b)return null
return r?-1:1},
eT(a){var t,s
if(a.c!==B.n)return!1
t=a.d
if(!t.h(0,B.I))return!1
if(t.az(0,new A.d9()))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.a_)&&s.h(0,B.f)&&s.h(0,B.e)&&s.h(0,B.i)},
j1(a,b){var t,s,r
if(!b.b||!b.p3)return!1
t=a.d
if(!t.h(0,B.v))return!1
s=t.a
if(s!==1){r=!1
if(!(s===2&&t.h(0,B.R)))if(t.a===3)if(t.h(0,B.R))s=t.h(0,B.o)||t.h(0,B.B)
else s=r
else s=r
else s=!0}else s=!0
return s},
j9(a,b,c,d,e){var t,s,r,q=null,p=c.k3&&c.ok&&c.p3&&c.to
if(p===(d.k3&&d.ok&&d.p3&&d.to))return q
t=p?b:a
s=p?d:c
if(!s.a)return q
r=t.a.c
if(r!==B.V&&r!==B.W)return q
if(s.R8===0)return q
if((p?a:b).b+0.55<t.b)return q
return p?-1:1},
jb(a,b,c,d,e){var t,s,r,q=c.k1&&c.p3
if(q===(d.k1&&d.p3))return null
t=q?d:c
if(!t.d||t.p4===0)return null
s=q?a:b
r=q?b:a
if(s.b+0.55<r.b)return null
return q?-1:1},
jv(a,b,c,d,e){var t,s,r,q=null,p=c.k4
if(p===d.k4)return q
t=p?b:a
s=(p?d:c).a&&t.a.c===B.S
r=t.a
if(!s&&r.c!==B.a4)return q
if(e.b===B.j&&s&&r.a===e.a.e)return q
if((p?a:b).b+0.55<t.b)return q
return p?-1:1},
j8(a,b,c,d,e){var t,s,r,q=null,p=c.dx,o=c.e,n=d.e
if(!(p&&n))t=d.dx&&o
else t=!0
if(!t)return q
s=p?c:d
r=p?d:c
if(!s.fx)return q
if(!s.go)return q
if(!r.ok)return q
if(!r.p2)return q
if(!s.x1)return q
return p?-1:1},
jM(a,b,c,d,e){var t,s,r,q=null
if(!c.dx||!d.dx)return q
if(c.a===d.a)return q
t=c.fy
s=t?c:d
r=t?d:c
if(!s.fy||!r.fx)return q
if(!s.go||!r.go)return q
if(s.p2&&!s.id)return t?-1:1
else return t?1:-1},
jE(a,b,c,d,e){var t,s=null,r=A.f_(a.a,c)
if(r===A.f_(b.a,d))return s
t=r?d:c
if(!t.dy)return s
if(!t.ok)return s
if(!t.go)return s
return r?-1:1},
jI(a,b,c,d,e){var t,s,r,q=null,p=A.eZ(a.a)
if(p===A.eZ(b.a))return q
t=(p?b:a).a
s=!1
if(t.c===B.C){r=t.d
if(r.a===2)s=(r.h(0,B.k)||r.h(0,B.v))&&r.h(0,B.w)}if(!s)return q
s=(p?a:b).a
if(s.a!==t.a)return q
if((s.f&128)!==0)return q
return p?-1:1},
eZ(a){var t,s=!1
if(a.c===B.y){t=a.d
if(t.a===2)s=(t.h(0,B.k)||t.h(0,B.v))&&t.h(0,B.o)}return s},
jD(a,b,c,d,e){var t,s,r,q,p=c.CW
if(p===d.CW)return null
if((p?c:d).rx.a[1]>0)return null
t=p?d:c
if(!t.ok)return null
s=p?b.a.c:a.a.c
if(s===B.t||s===B.D){r=t.rx.a
q=r[1]===0&&r[2]===0}else q=!1
if(q)return p?1:-1
return p?-1:1},
jd(a,b,c,d,e){var t=c.z
if(t===d.z)return null
if(!(t?d:c).Q)return null
return t?-1:1},
je(a,b,c,d,e){var t,s=c.z
if(s===d.z)return null
t=s?d:c
if(!t.c||!t.p2)return null
return s?-1:1},
f_(a,b){var t
if(!b.fx)return!1
if(!b.go)return!1
t=a.d
if(!t.h(0,B.k))return!1
return t.h(0,B.o)},
jh(a,b,c,d,e){var t,s,r=A.eU(a.a)
if(r===A.eU(b.a))return null
t=r?b:a
s=r?d:c
if(!A.iS(t.a,s))return null
return r?-1:1},
eU(a){var t,s
if(a.c!==B.n)return!1
t=a.d
if(t.a!==2||!t.h(0,B.I)||!t.h(0,B.p))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.a_)&&s.h(0,B.f)&&s.h(0,B.e)&&s.h(0,B.ae)&&s.h(0,B.i)},
iS(a,b){var t,s
if(a.c!==B.E||!b.p3)return!1
t=a.d
if(t.a!==2||!t.h(0,B.v)||!t.h(0,B.o))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.T)&&s.h(0,B.f)&&s.h(0,B.Y)&&s.h(0,B.e)&&s.h(0,B.O)},
ja(a,b,c,d,e){var t,s,r=A.eS(a.a)
if(r===A.eS(b.a))return null
t=r?b:a
s=t.a
if(!A.iX(s)&&!A.j0(s))return null
if((r?a:b).b+0.2<t.b)return null
return r?-1:1},
eS(a){var t,s
if(a.c!==B.y)return!1
t=a.d
if(!t.h(0,B.v)||!t.h(0,B.o))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.T)&&s.h(0,B.f)&&s.h(0,B.Y)&&s.h(0,B.u)&&s.h(0,B.i)},
j0(a){var t,s=a.c
A:{t=B.S===s||B.N===s||B.X===s
break A}return t&&a.d.a!==0},
iX(a){var t,s
if(a.c!==B.y)return!1
if(!a.d.h(0,B.q))return!1
t=a.e
s=new A.d(t,A.a(t).i("d<2>"))
return s.h(0,B.l)&&s.h(0,B.f)&&s.h(0,B.ac)&&s.h(0,B.u)&&s.h(0,B.i)},
jp(a,b,c,d,e){var t,s,r=null,q=c.d
if(!q&&!d.d)return r
if(q&&d.d){q=d.a
if(c.a===q)return r
return q?1:-1}t=q&&c.a
s=d.d&&d.a
if(t===s)return r
if(!(t?!d.a:!c.a))return r
return s?1:-1},
jr(a,b,c,d,e){var t,s,r,q=null,p=c.dx,o=c.d,n=d.d
if(!(p&&n))t=d.dx&&o
else t=!0
if(!t)return q
s=p?c:d
r=p?d:c
if(!s.go)return q
if(!r.ok)return q
if(!r.p2)return q
return p?-1:1},
jq(a,b,c,d,e){var t,s,r,q,p=null,o=c.fx&&c.go
if(o===(d.fx&&d.go))return p
t=o?c:d
s=o?d:c
r=o?a:b
q=o?b:a
if(!s.ok)return p
if(s.dx)return p
if(s.dy)return p
if(!t.x1)return p
if(r.b+0.25<q.b)return p
return o?-1:1},
jA(a,b,c,d,e){var t,s,r,q=null,p=c.at
if(p===d.at)return q
t=p?d:c
s=p?a:b
r=p?b:a
if(!t.ok)return q
if(t.R8===0&&!t.db)return q
if(s.b+0.55<r.b)return q
return p?-1:1},
jy(a,b,c,d,e){var t,s,r,q=null,p=c.ax
if(p===d.ax)return q
t=p?d:c
s=p?a:b
r=p?b:a
if(!t.ok)return q
if(r.a.c!==B.N)return q
if(s.b+0.55<r.b)return q
return p?-1:1},
jC(a,b,c,d,e){var t,s,r,q,p,o=null
if(!c.dy||!d.dy)return o
t=c.a
if(t===d.a)return o
s=t?c:d
r=t?d:c
q=t?a:b
p=t?b:a
if(!s.go||!r.go)return o
if(!s.to||r.to)return o
if(q.b+0.5<p.b)return o
return t?-1:1},
jl(a,b,c,d,e){var t,s,r,q,p=null,o=c.RG
if(o===d.RG)return p
t=o?a:b
s=o?b:a
r=o?c:d
q=o?d:c
if(!q.c)return p
if(q.R8===0)return p
if(q.p1>=r.p1)return p
if(s.b+0.55<t.b)return p
return o?1:-1},
jg(a,b,c,d,e){var t,s,r,q,p=null,o=c.r
if(o===d.r)return p
t=o?c:d
s=o?d:c
r=o?a:b
q=o?b:a
if(!t.ay)return p
if(!s.ch)return p
if(r.b+0.35<q.b)return p
return o?-1:1},
jB(a,b,c,d,e){var t,s,r,q=c.cx
if(q===d.cx)return null
t=q?d:c
if(!t.f||!t.ok)return null
s=q?a:b
r=q?b:a
if(s.b+1.5<r.b)return null
return q?-1:1},
ji(a,b,c,d,e){var t,s,r,q,p=null
if(c.y){t=c.rx.a
s=t[1]===0&&t[2]===0}else s=!1
if(d.y){t=d.rx.a
r=t[1]===0&&t[2]===0}else r=!1
if(s===r)return p
q=s?d:c
if(!q.c)return p
t=q.rx.a
if(t[1]>0)return p
if(t[2]>0)return p
return s?-1:1},
jJ(a,b,c,d,e){var t,s,r,q,p=null,o=!c.c&&!c.f&&c.x2
if(o===(!d.c&&!d.f&&d.x2))return p
t=o?d:c
if(!t.c)return p
if(!t.db)return p
if(t.rx.a[3]>0)return p
if(t.a)return p
s=o?c:d
if(t.k3&&!s.a)return p
r=o?a:b
q=o?b:a
if(r.b+1.5<q.b)return p
return o?-1:1},
jj(a,b,c,d,e){var t,s,r=c.y
if(r===d.y)return null
if(!(r?d:c).cy)return null
t=r?a:b
s=r?b:a
if(t.b+0.55<s.b)return null
return r?-1:1},
js(a,b,c,d,e){var t,s,r=null,q=c.fy
if(q===d.fy)return r
t=q?c:d
s=q?d:c
if(!t.go)return r
if(!t.p2)return r
if(!s.c)return r
if(s.dx)return r
if(!s.ok)return r
return q?-1:1},
jw(a,b,c,d,e){var t=c.xr>0
if(t===d.xr>0)return null
return t?1:-1},
jx(a,b,c,d,e){var t,s,r,q
if(e.b!==B.j)return null
t=new A.da(e)
s=t.$2(a,c)
if(s===t.$2(b,d))return null
r=s?b:a
q=s?d:c
if(!new A.db().$2(r,q))return null
return s?-1:1},
jt(a,b,c,d,e){var t=B.a.A(c.R8,d.R8)
if(t===0)return null
return t},
jo(a,b,c,d,e){var t=e.O(a.a),s=e.O(b.a)!=null
if(t!=null===s)return null
return s?1:-1},
jG(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k=a.a.c===B.M
if(k===(b.a.c===B.M))return null
t=k?a:b
s=k?c:d
r=k?b:a
q=k?d:c
if(s.a){p=r.a
p=p.c!==B.E||!q.ok||p.b!==t.a.a}else p=!0
if(p)return null
o=t.a.d
n=r.a.d
p=o.a
m=p===0&&n.a===0
l=p===1&&o.h(0,B.B)&&n.a===1&&n.h(0,B.A)
if(!m&&!l)return null
return k?-1:1},
jL(a,b,c,d,e){var t,s=e.O(a.a),r=e.O(b.a)
if(s==null||r==null)return null
t=r===B.Q
if(s===B.Q===t)return null
return t?1:-1},
jK(a,b,c,d,e){var t,s=a.a,r=e.O(s),q=e.O(b.a)
if(r==null||q==null)return null
if(s.b!==e.a.e)return null
t=q===B.Q
if(r===B.Q===t)return null
return t?1:-1},
jz(a,b,c,d,e){var t,s,r=d.rx.a,q=c.rx.a,p=B.a.A(r[2],q[2])
if(p!==0)return p
t=B.a.A(q[0],r[0])
if(t!==0)return t
s=B.a.A(q[3],r[3])
if(s!==0)return s
return null},
jH(a,b,c,d,e){var t=d.a
if(c.a===t)return null
return t?1:-1},
jm(a,b,c,d,e){var t=B.a.A(c.p1,d.p1)
if(t===0)return null
return t},
j7(a,b,c,d,e){var t=d.c
if(c.c===t)return null
return t?1:-1},
ju(a,b,c,d,e){var t=B.a.A(c.p4,d.p4)
if(t===0)return null
return t},
iA(a,b,c,d,e){var t=c.f
if(t===d.f)return null
return t?1:-1},
bg:function bg(a,b){this.a=a
this.b=b},
d9:function d9(){},
da:function da(a){this.a=a},
db:function db(){},
bE:function bE(a,b,c){this.a=a
this.b=b
this.c=c},
I:function I(a,b){this.a=a
this.b=b},
b3(a){switch(a.a){case 0:return 1
case 11:return 2
case 1:return 3
case 2:return 4
case 3:return 5
case 4:return 6
case 5:return 7
case 6:return 8
case 7:return 9
case 8:return 10
case 9:return 11
case 10:return 12}},
e7(a){switch(a.a){case 0:return"b9"
case 11:return"addb9"
case 1:return"9"
case 2:return"#9"
case 3:return"add#9"
case 4:return"11"
case 5:return"#11"
case 6:return"b13"
case 7:return"13"
case 8:return"add9"
case 9:return"add11"
case 10:return"add13"}},
ds(a){switch(a.a){case 0:return"flat nine"
case 11:return"added flat nine"
case 1:return"nine"
case 2:return"sharp nine"
case 3:return"added sharp nine"
case 4:return"eleven"
case 5:return"sharp eleven"
case 6:return"flat thirteen"
case 7:return"thirteen"
case 8:return"added nine"
case 9:return"added eleven"
case 10:return"added thirteen"}},
cr(a){switch(a.a){case 8:case 11:case 3:case 9:case 10:return!0
default:return!1}},
hh(a){switch(a.a){case 1:case 4:case 7:return!0
default:return!1}},
hg(a){switch(a.a){case 0:case 2:case 5:case 6:return!0
default:return!1}},
k7(a,b){var t,s,r,q,p,o
for(t=A.ai(a,a.r,A.a(a).c),s=t.$ti.c,r=0,q=0,p=0;t.k();){o=t.d
if(o==null)o=s.a(o)
if(A.cr(o))++p
else{if(A.hg(o))o=!(b&&o===B.o)
else o=!1
if(o)++r
else ++q}}return new A.bv([p,r,q,a.a])},
dr(a){switch(a.a){case 0:case 11:return 1
case 1:case 8:return 2
case 2:case 3:return 3
case 4:case 9:return 5
case 5:return 6
case 6:return 8
case 7:case 10:return 9}},
o:function o(a,b){this.a=a
this.b=b},
hk(a,b,c){var t,s,r
if(a===b)return!0
if(a.a!==b.a)return!1
for(t=A.ai(a,a.r,A.a(a).c),s=t.$ti.c;t.k();){r=t.d
if(!b.h(0,r==null?s.a(r):r))return!1}return!0},
hl(a,b){var t,s,r,q
for(t=A.ai(a,a.r,A.a(a).c),s=t.$ti.c,r=0;t.k();){q=t.d
r=(r^J.t(q==null?s.a(q):q))>>>0}return r},
hi(a,b,c,d){var t,s,r
if(a===b)return!0
if(a.a!==b.a)return!1
for(t=new A.W(a,A.a(a).i("W<1,2>")).gq(0);t.k();){s=t.d
r=s.a
if(!b.S(r))return!1
if(!J.Z(b.p(0,r),s.b))return!1}return!0},
hj(a,b,c){var t,s,r
for(t=new A.W(a,A.a(a).i("W<1,2>")).gq(0),s=0;t.k();){r=t.d
s^=A.a6(r.a,r.b,B.d,B.d,B.d,B.d)}return s},
P(a){switch(a.a){case 11:case 12:case 13:case 14:case 15:case 16:case 17:case 18:case 19:case 20:case 21:case 22:case 23:case 24:case 25:return B.r
default:return B.b8}},
aF(a){switch(a.a){case 9:case 10:return!0
default:return!1}},
du(a){switch(a.a){case 6:case 7:case 8:case 12:case 13:case 17:case 18:return!0
default:return!1}},
e9(a){switch(a.a){case 0:case 9:case 16:return!0
default:return!1}},
bJ:function bJ(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
l:function l(a,b){this.a=a
this.b=b},
bM:function bM(a,b){this.a=a
this.b=b},
bK:function bK(a,b,c){this.a=a
this.b=b
this.c=c},
ea(a){var t
A:{if(B.l===a){t=1
break A}if(B.K===a){t=2
break A}if(B.m===a||B.ap===a||B.f===a){t=3
break A}if(B.L===a){t=4
break A}if(B.x===a||B.e===a||B.u===a){t=5
break A}if(B.O===a){t=6
break A}if(B.Z===a||B.i===a||B.z===a){t=7
break A}if(B.T===a||B.ao===a||B.a_===a||B.af===a||B.aN===a){t=9
break A}if(B.ac===a||B.Y===a||B.ad===a){t=11
break A}if(B.am===a||B.ae===a||B.an===a){t=13
break A}t=null}return t},
hv(a){switch(a.a){case 0:return 1
case 1:case 2:case 3:case 4:case 5:case 6:return 2
case 7:case 8:case 9:return 3
case 10:case 11:case 12:case 13:return 4
case 14:case 15:case 16:return 5
case 17:case 18:case 19:case 20:return 6
case 21:case 22:case 23:return 7}},
n:function n(a,b){this.a=a
this.b=b},
dA(a){var t,s,r,q
for(t=a.b,s=t===B.j,t=t===B.h,r=0;r<15;++r){q=B.bX[r]
if(t&&q.b.B(0,a))return q
if(s&&q.c.B(0,a))return q}throw A.c(A.dJ("No KeySignature found for tonality "+a.j(0)))},
C:function C(a,b,c){this.a=a
this.b=b
this.c=c},
cK:function cK(a){this.a=a},
hL(a){var t=A.i(a.slice(0),A.G(a))
B.c.aH(t)
if(t.length<2)return B.aQ
return new A.aP(A.dE(t,u.S),B.aK)},
hM(a){var t,s,r,q,p,o,n=J.dx(a.slice(0),A.G(a).c)
if(n.length<2)return B.aQ
t=A.i([],u.t)
for(s=n.length,r=48,q=0;q<n.length;n.length===s||(0,A.O)(n),++q){p=B.a.m(B.a.m(n[q],12)+12,12)
o=r-B.a.m(r,12)+p
if(o<r)o+=12
B.c.l(t,o)
r=o+1}return new A.aP(A.dE(t,u.S),B.cN)},
hN(a,b){var t,s,r,q
if(a===b)return!0
t=a.length
s=b.length
if(t!==s)return!1
for(r=0;r<t;++r){q=a[r]
if(!(r<s))return A.b(b,r)
if(q!==b[r])return!1}return!0},
c9:function c9(a,b){this.a=a
this.b=b},
aP:function aP(a,b){this.a=a
this.b=b},
a7:function a7(a,b){this.a=a
this.b=b},
aR:function aR(a,b){this.a=a
this.b=b},
cO:function cO(a,b){this.a=a
this.b=b},
c7:function c7(a,b){this.a=a
this.b=b},
j:function j(a,b){this.a=a
this.b=b},
i5(a){var t,s
for(t=0;t<21;++t){s=B.bY[t]
if(s.c===a)return s}return null},
x:function x(a,b,c,d,e){var _=this
_.c=a
_.d=b
_.e=c
_.a=d
_.b=e},
u(a){var t=$.fv().p(0,a)
t.toString
return t},
aC(a){var t
for(t=0;a!==0;){a=(a&a-1)>>>0;++t}return t},
m:function m(a,b,c){this.a=a
this.b=b
this.c=c},
hw(a,b,c){var t,s,r,q,p,o=A.aM(u.S,u.u),n=new A.cx(c)
if(n.$1(0))o.u(0,0,B.l)
t=new A.cv(n,o)
switch(b.a){case 0:t.$2(4,B.f)
t.$2(7,B.e)
break
case 1:t.$2(4,B.f)
t.$2(6,B.x)
break
case 2:t.$2(3,B.m)
t.$2(7,B.e)
break
case 3:t.$2(3,B.m)
t.$2(8,B.u)
break
case 4:t.$2(3,B.m)
t.$2(6,B.x)
break
case 5:t.$2(4,B.f)
t.$2(8,B.u)
break
case 6:t.$2(2,B.K)
t.$2(7,B.e)
break
case 7:t.$2(5,B.L)
t.$2(7,B.e)
break
case 8:t.$2(2,B.K)
t.$2(5,B.L)
t.$2(7,B.e)
break
case 9:t.$2(4,B.f)
t.$2(7,B.e)
t.$2(9,B.O)
break
case 10:t.$2(3,B.m)
t.$2(7,B.e)
t.$2(9,B.O)
break
case 11:t.$2(4,B.f)
t.$2(7,B.e)
t.$2(10,B.i)
break
case 12:t.$2(2,B.K)
t.$2(7,B.e)
t.$2(10,B.i)
break
case 13:t.$2(5,B.L)
t.$2(7,B.e)
t.$2(10,B.i)
break
case 14:t.$2(4,B.f)
t.$2(6,B.x)
t.$2(10,B.i)
break
case 15:t.$2(4,B.f)
t.$2(8,B.u)
t.$2(10,B.i)
break
case 16:t.$2(4,B.f)
t.$2(7,B.e)
t.$2(11,B.z)
break
case 17:t.$2(2,B.K)
t.$2(7,B.e)
t.$2(11,B.z)
break
case 18:t.$2(5,B.L)
t.$2(7,B.e)
t.$2(11,B.z)
break
case 19:t.$2(4,B.f)
t.$2(6,B.x)
t.$2(11,B.z)
break
case 20:t.$2(4,B.f)
t.$2(8,B.u)
t.$2(11,B.z)
break
case 21:t.$2(3,B.m)
t.$2(7,B.e)
t.$2(10,B.i)
break
case 22:t.$2(3,B.m)
t.$2(8,B.u)
t.$2(10,B.i)
break
case 23:t.$2(3,B.m)
t.$2(7,B.e)
t.$2(11,B.z)
break
case 24:t.$2(3,B.m)
t.$2(6,B.x)
t.$2(10,B.i)
break
case 25:t.$2(3,B.m)
t.$2(6,B.x)
t.$2(9,B.Z)
break}s=new A.cw(n,o)
for(r=A.ai(a,a.r,A.a(a).c),q=r.$ti.c;r.k();){p=r.d
switch((p==null?q.a(p):p).a){case 0:case 11:s.$2(1,B.T)
break
case 1:s.$2(2,B.ao)
break
case 2:s.$2(3,B.a_)
break
case 3:s.$2(3,B.ap)
break
case 4:s.$2(5,B.ac)
break
case 5:s.$2(6,B.Y)
break
case 6:s.$2(8,B.am)
break
case 7:s.$2(9,B.ae)
break
case 8:s.$2(2,B.af)
break
case 9:s.$2(5,B.ad)
break
case 10:s.$2(9,B.an)
break}}return o},
cx:function cx(a){this.a=a},
cv:function cv(a,b){this.a=a
this.b=b},
cw:function cw(a,b){this.a=a
this.b=b},
dj(a,b,c,d){var t,s,r,q,p
if(c!=null)t=B.b.G(b).length===0
else t=!0
if(t)return A.aY(a,d)
s=A.am(b)
if(0>=s.length)return A.b(s,0)
r=B.c.U(B.H,s[0].toUpperCase())
if(r===-1)return A.aY(a,d)
q=B.H[B.a.m(r+(A.hv(c)-1),7)]
t=B.ag.p(0,q)
t.toString
p=B.a.m(B.a.m(a,12)-t,12)
if(p>6)p-=12
if(p<-2||p>2)return A.aY(a,d)
return q+A.d4(p)},
di(a,b){var t,s,r,q,p,o,n,m,l=a.a,k=A.aY(l,b),j=A.eM(A.dA(b).a,b.a.d)
if(new A.d(j,A.a(j).i("d<2>")).h(0,A.am(k)))return k
t=A.iC(l)
for(l=t.length,s=null,r=0;r<t.length;t.length===l||(0,A.O)(t),++r){q=t[r]
p=A.jQ(a,q,k,b)
o=new A.d0(q,p)
n=!0
if(s!=null){m=s.b
if(p>=m)n=p===m&&q===k}if(n)s=o}l=s==null?null:s.a
return l==null?k:l},
aY(a,b){var t=B.a.m(a,12),s=A.dA(b).a,r=b.a.d,q=A.eM(s,r),p=q.p(0,t)
if(p!=null)return p
return A.jV(t,q,s,r)},
eI(a){var t,s,r,q=A.aM(u.N,u.S)
for(t=0;t<7;++t)q.u(0,B.H[t],0)
if(a>0)for(s=0;s<a;++s){if(!(s<7))return A.b(B.aP,s)
q.u(0,B.aP[s],1)}else if(a<0)for(r=-a,s=0;s<r;++s){if(!(s<7))return A.b(B.aO,s)
q.u(0,B.aO[s],-1)}return q},
eM(a,b){var t,s,r,q,p,o,n=B.c.U(B.H,b),m=n===-1?0:n,l=A.eI(a),k=u.N,j=J.dx(new Array(7),k)
for(t=0;t<7;++t)j[t]=B.H[B.a.m(m+t,7)]
s=A.aM(u.S,k)
for(k=j.length,r=0;r<k;++r){q=j[r]
p=B.ag.p(0,q)
p.toString
o=l.p(0,q)
o.toString
s.u(0,B.a.m(p+o,12),q+A.d4(o))}return s},
jV(a,b,c,d){var t,s,r,q,p,o,n,m,l,k,j,i=A.eI(c),h=A.a(b).i("d<2>"),g=new A.de(A.dD(new A.d(b,h),h.i("e.E")))
for(h=c<0,t=c>0,s=null,r=0;r<7;++r){q=B.H[r]
p=i.p(0,q)
p.toString
o=B.ag.p(0,q)
o.toString
n=B.a.m(a-B.a.m(o+p,12),12)
if(n>6)n-=12
if(n<-2||n>2)continue
m=p+n
if(m<-2||m>2)continue
l=q+A.d4(m)
if((l==="B#"||l==="Cb"||l==="E#"||l==="Fb")&&!g.$1(l))continue
k=Math.abs(n)*10
if(Math.abs(m)===2)k+=60
if(t&&m>0)--k
if(h&&m<0)--k
j=new A.cT(l,k)
if(s==null||k<s.b)s=j}h=s==null?null:s.a
return h==null?B.c3[B.a.m(a,12)]:h},
d4(a){var t
A:{t=""
if(-2===a){t="bb"
break A}if(-1===a){t="b"
break A}if(0===a)break A
if(1===a){t="#"
break A}if(2===a){t="x"
break A}break A}return t},
iC(a){var t,s,r,q,p=B.a.m(a,12),o=A.i([],u.s)
for(t=0;t<7;++t){s=B.H[t]
r=B.ag.p(0,s)
r.toString
q=B.a.m(p-r,12)
if(q>6)q-=12
if(q<-1||q>1)continue
B.c.l(o,s+A.d4(q))}return o},
jQ(a,b,c,d){var t,s,r,q=b!==c?3:0
q+=A.f3(b)
for(t=a.e,t=new A.W(t,A.a(t).i("W<1,2>")).gq(0),s=a.a;t.k();){r=t.d
q+=A.f3(A.dj(B.a.m(s+r.a,12),b,r.b,d))}return q},
f3(a){var t,s,r,q,p,o,n=A.am(a)
if(n.length===0)return 1000
t=B.b.E(n,1)
for(s=t.split(""),r=s.length,q=0,p=0;p<r;++p){o=s[p]
if(o==="#"||o==="b")q+=10
if(o==="x")q+=20}if(t.length===2)q+=30
return n==="B#"||n==="Cb"||n==="E#"||n==="Fb"?q+16:q},
de:function de(a){this.a=a},
cT:function cT(a,b){this.a=a
this.b=b},
d0:function d0(a,b){this.a=a
this.b=b},
bL:function bL(a,b){this.a=a
this.b=b},
cI:function cI(a,b){this.a=a
this.b=b},
dv:function dv(a,b,c){this.a=a
this.b=b
this.c=c},
hf(a){var t,s=a.b,r=a.a
if(s===r)return!1
if(A.P(a.c)!==B.r)return!1
t=a.d
if(t.a!==1||!t.h(0,B.k))return!1
return B.a.m(s-r,12)===2},
he(a){var t,s=a.b,r=a.a
if(s===r)return!1
t=a.e.p(0,A.al(s,r))
if(t==null)return!1
return t===B.f||t===B.m||t===B.e||t===B.x||t===B.u||t===B.O||t===B.i||t===B.z||t===B.Z},
e6(a){var t,s,r,q,p
if(A.hf(a))return B.aS
t=a.b
s=a.a
if(t===s)return a.d
r=a.d
q=A.a(r)
p=q.i("as<1>")
return A.dD(new A.as(r,q.i("H(1)").a(new A.cq(B.a.m(t-s,12))),p),p.i("e.E"))},
cq:function cq(a){this.a=a},
eN(a,b,c){var t,s,r,q,p,o=A.ah(a,A.a(a).c)
B.c.R(o,new A.d5())
t=u.s
s=A.i([],t)
t=A.i([],t)
if(c!=null)t.push(c)
for(r=o.length,q=0;q<o.length;o.length===r||(0,A.O)(o),++q){p=o[q]
if(A.iR(p,b))continue
if(A.cr(p))B.c.l(s,A.ds(p))
else B.c.l(t,A.ds(p))}t=A.ah(t,u.N)
B.c.W(t,s)
return t},
iH(a,b,c){var t=A.eN(a,b,c)
if(t.length===0)return""
return" with "+A.iG(t)},
jN(a,b){var t,s,r=A.e8(b,B.bB),q=A.dt(b),p=q!=null?B.b.L(r," "+q,""):r,o=A.dO(a,b)
if(o==null)return p
A:{if(B.k===o){t="ninth"
break A}if(B.q===o){t="eleventh"
break A}if(B.p===o){t="thirteenth"
break A}t=A.ds(o)
break A}s=A.jP(p,t)
return s===p?p:s},
dO(a,b){if(A.P(b)!==B.r||b===B.J)return null
if(a.h(0,B.p))return B.p
if(a.h(0,B.q))return B.q
if(a.h(0,B.k))return B.k
return null},
iR(a,b){switch(b){case B.k:return a===B.k
case B.q:return a===B.k||a===B.q
case B.p:return a===B.k||a===B.q||a===B.p
case B.A:return a===B.A
default:return!1}},
jP(a,b){if(B.b.h(a,"seventh"))return B.b.L(a,"seventh",b)
return a},
f2(a,b,c){var t
switch(b.a){case 0:t=new A.a0(c).H(a)
break
case 1:t=new A.a0(c).aJ(a,!1)
break
default:t=null}return t},
iG(a){var t,s=a.length
if(s===0)return""
if(s===1)return B.c.gaG(a)
if(s===2){if(0>=s)return A.b(a,0)
t=a[0]
if(1>=s)return A.b(a,1)
return t+" and "+a[1]}return B.c.J(B.c.aK(a,0,s-1),", ")+", and "+B.c.gbb(a)},
cs:function cs(a,b){this.a=a
this.b=b},
d5:function d5(){},
hq(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i,h,g=null,f=b===B.ah?B.bz:B.bA,e=A.e8(c,f),d=A.ah(a,A.a(a).c)
B.c.R(d,new A.ct())
if(A.aF(c)&&a.h(0,B.A))e+="/9"
t=a.h(0,B.k)
s=a.h(0,B.q)
r=a.h(0,B.p)
if(A.P(c)===B.r&&A.hm(f,c))if(r)q=B.p
else if(s)q=B.q
else q=t?B.k:g
else q=g
if(q!=null){p=A.ho(e,A.e7(q))
if(p!==e)e=p
else q=g}o=A.i([],u._)
n=A.aF(c)&&B.b.X(e,"/9")
for(m=d.length,l=q===B.q,k=q===B.p,j=0;j<d.length;d.length===m||(0,A.O)(d),++j){i=d[j]
if(i===q)continue
if(n&&i===B.A)continue
if(k){if(i===B.k||i===B.q)continue}else if(l)if(i===B.k)continue
B.c.l(o,A.hn(i,c))}if(o.length===0)return e
m=u.Y
h=A.ah(new A.L(o,u.q.a(new A.cu()),m),m.i("F.E"))
if(A.hp(o,b,c))return e+"("+B.c.J(h,b===B.ah?"":",")+")"
return e+B.c.ba(h)},
hm(a,b){switch(b.a){case 11:case 12:case 13:case 14:case 15:case 16:case 17:case 18:case 19:case 20:case 21:case 22:case 23:case 24:return!0
default:return!1}},
hn(a,b){if(b===B.J&&A.hh(a))switch(a.a){case 1:return B.A
case 4:return B.B
case 7:return B.a9
default:return a}return a},
ho(a,b){var t
if(B.b.a5(a,"7sus"))return b+B.b.E(a,1)
if(B.b.a5(a,"maj7sus"))return"maj"+b+B.b.E(a,4)
if(B.b.h(a,"7#5"))return B.b.L(a,"7#5",b+"#5")
if(B.b.h(a,"7\u266f5"))return B.b.L(a,"7\u266f5",b+"\u266f5")
if(B.b.h(a,"7b5"))return B.b.L(a,"7b5",b+"b5")
if(B.b.h(a,"7\u266d5"))return B.b.L(a,"7\u266d5",b+"\u266d5")
if(B.b.h(a,"(maj7)"))return B.b.L(a,"(maj7)","(maj"+b+")")
t=B.b.U(a,"7(")
if(t!==-1&&B.b.X(a,")"))return B.b.D(a,0,t)+b+B.b.E(a,t+1)
if(B.b.h(a,"("))return a
if(a==="7")return b
if(B.b.X(a,"7"))return B.b.D(a,0,a.length-1)+b
return a},
hp(a,b,c){var t
if(c===B.J)return!0
t=a.length
if(t===0)return!1
if(A.P(c)===B.r&&A.du(c))return!0
if(t===1){if(A.cr(B.c.gT(a)))return A.P(c)===B.r
return!1}return!0},
ct:function ct(){},
cu:function cu(){},
e8(a,b){switch(b.a){case 0:return A.hu(a)
case 1:return A.ht(a)
case 2:return A.hr(a)
case 3:return A.hs(a)}},
hu(a){switch(a.a){case 0:return""
case 1:return"(\u266d5)"
case 2:return"\u2212"
case 3:return"\u2212\u266f5"
case 4:return"\xb0"
case 5:return"+"
case 6:return"sus2"
case 7:return"sus4"
case 8:return"sus2sus4"
case 9:return"6"
case 10:return"\u22126"
case 11:return"7"
case 12:return"7sus2"
case 13:return"7sus4"
case 14:return"7\u266d5"
case 15:return"7\u266f5"
case 16:return"\u03947"
case 17:return"\u03947sus2"
case 18:return"\u03947sus4"
case 19:return"\u03947\u266d5"
case 20:return"\u03947\u266f5"
case 21:return"\u22127"
case 22:return"\u22127\u266f5"
case 23:return"\u2212\u03947"
case 24:return"\xf87"
case 25:return"\xb07"}},
ht(a){switch(a.a){case 0:return""
case 1:return"(b5)"
case 2:return"m"
case 3:return"m#5"
case 4:return"dim"
case 5:return"aug"
case 6:return"sus2"
case 7:return"sus4"
case 8:return"sus2sus4"
case 9:return"6"
case 10:return"m6"
case 11:return"7"
case 12:return"7sus2"
case 13:return"7sus4"
case 14:return"7b5"
case 15:return"7#5"
case 16:return"maj7"
case 17:return"maj7sus2"
case 18:return"maj7sus4"
case 19:return"maj7b5"
case 20:return"maj7#5"
case 21:return"m7"
case 22:return"m7#5"
case 23:return"m(maj7)"
case 24:return"m7(b5)"
case 25:return"dim7"}},
hr(a){switch(a.a){case 0:return"major"
case 1:return"major flat five"
case 2:return"minor"
case 3:return"minor sharp five"
case 4:return"diminished"
case 5:return"augmented"
case 6:return"suspended second"
case 7:return"suspended fourth"
case 8:return"suspended second and fourth"
case 9:return"major sixth"
case 10:return"minor sixth"
case 11:return"dominant seventh"
case 12:return"dominant seventh suspended second"
case 13:return"dominant seventh suspended fourth"
case 14:return"dominant seventh flat five"
case 15:return"dominant seventh sharp five"
case 16:return"major seventh"
case 17:return"major seventh suspended second"
case 18:return"major seventh suspended fourth"
case 19:return"major seventh flat five"
case 20:return"major seventh sharp five"
case 21:return"minor seventh"
case 22:return"minor seventh sharp five"
case 23:return"minor-major seventh"
case 24:return"half-diminished seventh"
case 25:return"diminished seventh"}},
hs(a){switch(a.a){case 0:return""
case 1:return"flat five"
case 2:return"minor"
case 3:return"minor sharp five"
case 4:return"diminished"
case 5:return"augmented"
case 6:return"sus two"
case 7:return"sus"
case 8:return"sus two sus four"
case 9:return"six"
case 10:return"minor six"
case 11:return"seven"
case 12:return"seven sus two"
case 13:return"seven sus"
case 14:return"seven flat five"
case 15:return"seven sharp five"
case 16:return"major seven"
case 17:return"major seven sus two"
case 18:return"major seven sus"
case 19:return"major seven flat five"
case 20:return"major seven sharp five"
case 21:return"minor seven"
case 22:return"minor seven sharp five"
case 23:return"minor major seven"
case 24:return"half-diminished"
case 25:return"diminished seven"}},
dt(a){switch(a.a){case 1:case 14:case 19:return"flat five"
case 3:case 15:case 20:case 22:return"sharp five"
default:return null}},
b4:function b4(a,b){this.a=a
this.b=b},
dm(a){var t=A.S(a,"bb","\ud834\udd2b")
t=A.S(t,"x","\ud834\udd2a")
t=A.S(t,"#","\u266f")
return A.S(t,"b","\u266d")},
ff(a){var t,s
A:{t=new A.a0(B.P).H(a.a.c)
s=a.b===B.h?"major":"minor"
s=t+" "+s
t=s
break A}return t},
ew(a){var t,s=B.b.G(a),r=s.length
if(r===0)return null
if(0>=r)return A.b(s,0)
t=s[0].toUpperCase()
if(!B.b.h("ABCDEFG",t))return null
return new A.cZ(t,B.b.E(s,1))},
a0:function a0(a){this.a=a},
cZ:function cZ(a,b){this.a=a
this.b=b},
fE(a){var t
switch(a.a){case 0:t="chosen"
break
case 1:t="near-tie"
break
case 2:t="unlikely"
break
default:t=null}return t},
kd(b8,b9,c0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7=null
if(b8.length>512)return new A.ac(!1,B.G,"",A.ff(A.fd(b9)),B.a6,B.G,B.c_)
t=A.fd(b9)
s=A.dA(t)
r=A.ff(t)
q=A.l4(b8)
p=q.length
if(p===0)return new A.ac(!1,B.G,"",r,B.a6,B.G,B.bW)
if(p>128)return new A.ac(!1,B.G,"",r,B.a6,B.G,B.bV)
o=A.kj(q)
p=o.b
if(p.length===0){p=A.i([],u.s)
n=o.e
if(n.length===0)p.push("Could not parse any notes.")
else p.push("Not a note: "+A.eQ(n)+". Use note names like C, F#, Bb, or MIDI numbers 0-127.")
return new A.ac(!1,B.G,"",r,B.a6,B.G,p)}n=A.i([],u.s)
m=o.e
if(m.length!==0)n.push("Ignored: "+A.eQ(m)+".")
l=o.a
k=l.length!==0?B.a.m(B.c.be(l,new A.df()),12):B.c.gT(p)
m=A.f4(p)
j=B.a.P(1,k)
i=A.f4(p)
h=l.length
h=h!==0?h:p.length
i=(i&j)>>>0===0?1:0
g=A.ke(o,t)
f=o.c.p(0,k)
e=f!=null?A.am(f):A.aY(k,t)
d=new A.a0(B.P).H(e)
c=l.length>=2?A.hL(l):A.hM(p)
b=A.h9(new A.bK((m|j)>>>0,k,h+i),new A.bE(t,s,new A.cK(s.a<0)),5,c)
if(b.length===0)return new A.ac(!0,g,d,r,B.a6,n,B.G)
a=B.c.gT(b).b
a0=A.i([],u.U)
for(a1=0;a1<b.length;){a2=b[a1]
if(a1===0)a3=B.b3
else a3=a-a2.b<=0.2?B.b4:B.b5;++a1
p=a2.a
a4=A.di(p,t)
m=p.b
j=p.a
i=m!==j
a5=i?A.dj(m,a4,p.e.p(0,B.a.m(m-j,12)),t):b7
h=p.c
a6=A.hq(A.e6(p),c0,h)
a7=a5==null?b7:B.b.G(a5)
a8=a7==null||a7.length===0?b7:a7
a9=new A.a0(B.P)
e=A.S(a6,"bb","\ud834\udd2b")
e=A.S(e,"x","\ud834\udd2a")
e=A.S(e,"#","\u266f")
a6=A.S(e,"b","\u266d")
e=a9.H(a4)
b0=a8!=null?a9.H(a8):b7
e+=a6
e=b0==null?e:e+" / "+b0
b1=A.di(p,t)
a4=A.f2(b1,B.aL,B.P)
b2=A.e6(p)
a6=A.jN(b2,h)
b3=A.iH(b2,A.dO(b2,h),A.dt(h))
b4=A.eN(b2,A.dO(b2,h),A.dt(h)).length
b5=a4+" "+a6+b3
if(i){a5=A.f2(A.dj(m,b1,p.e.p(0,B.a.m(m-j,12)),t),B.aL,B.P)
if(a5!==a4){b6=A.he(p)?"slash":"over"
b5=b5+(b4>=2?",":"")+" "+b6+" "+a5}}m=a2.b
B.c.l(a0,new A.bI(a1,e,B.b.G(b5),A.jU(p,t),A.jT(p,o,t),m,m-a,a3))}return new A.ac(!0,g,d,r,a0,n,B.G)},
l4(a){var t=B.b.aI(a,A.el("[\\s,-]+")),s=A.G(t),r=s.i("L<1,h>")
r=new A.L(t,s.i("h(1)").a(new A.dk()),r).aL(0,r.i("H(F.E)").a(new A.dl()))
t=A.ah(r,r.$ti.i("e.E"))
return t},
fd(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g=B.b.G(a)
if(g.length===0)return B.aU
r=A.el("\\s+")
q=A.S(g,r,"")
t=null
p=B.b.U(q,":")
if(p>=0){t=B.b.D(q,0,p)
o=B.b.E(q,p+1)}else{t=q
o=null}if(o!=null){n=o.toLowerCase()
m=n==="min"||n==="minor"?B.j:B.h}else{l=t.toLowerCase()
k=0
for(;;){if(!(k<4)){m=B.h
break}A:{j=B.c2[k]
if(!B.b.X(l,j))break A
m=B.b.a5(j,"min")?B.j:B.h
t=J.fB(t,0,J.bC(t)-j.length)
break}++k}}s=null
try{i=A.i5(A.am(t))
s=i==null?B.a8:i}catch(h){if(A.dW(h) instanceof A.T)s=B.a8
else throw h}return new A.j(s,m)},
kj(a){var t,s,r,q,p,o,n=u.t,m=A.i([],n),l=A.i([],n),k=A.aM(u.S,u.N),j=A.i([],u.k),i=A.i([],u.s)
for(n=a.length,r=0;r<a.length;a.length===n||(0,A.O)(a),++r){t=B.b.G(a[r])
if(J.bC(t)===0)continue
q=A.hP(t,null)
if(q!=null){if(q<0||q>127){J.b0(i,t)
continue}B.c.l(m,q)
p=B.a.m(q,12)
J.b0(l,p)
J.b0(j,new A.aV(q,null,p))
continue}try{s=A.kk(t)
J.b0(l,s)
k.bd(s,new A.dh(t))
J.b0(j,new A.aV(null,t,s))}catch(o){if(A.dW(o) instanceof A.T)J.b0(i,t)
else throw o}}return new A.cJ(m,l,k,j,i)},
ke(a,b){var t,s,r,q,p,o=A.cF(u.S),n=A.i([],u.s)
for(t=a.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.O)(t),++r){q=t[r]
p=q.a
if(p==null||o.l(0,p)){p=q.b
p=p!=null?A.am(p):A.aY(q.c,b)
n.push(new A.a0(B.P).H(p))}}return n},
jU(a,b){var t,s,r,q,p,o,n=A.di(a,b),m=A.aM(u.S,u.u)
m.u(0,0,B.l)
m.W(0,a.e)
t=m.$ti.i("a4<1>")
s=A.ah(new A.a4(m,t),t.i("e.E"))
B.c.R(s,new A.dd(m))
t=A.i([],u.s)
for(r=s.length,q=a.a,p=0;p<s.length;s.length===r||(0,A.O)(s),++p){o=s[p]
t.push(new A.a0(B.P).H(A.dj(B.a.m(q+o,12),n,m.p(0,o),b)))}return B.c.J(t," ")},
jT(a,b,c){var t,s,r,q,p,o=a.e,n=u.S,m=new A.a4(o,A.a(o).i("a4<1>")).b5(0,B.a.K(1,a.a),new A.dc(a),n),l=A.cF(n)
n=A.i([],u.s)
for(o=b.d,t=o.length,s=0;s<o.length;o.length===t||(0,A.O)(o),++s){r=o[s]
q=r.c
if(l.l(0,q)&&(m&B.a.P(1,q))>>>0===0){p=r.b
q=p!=null?A.am(p):A.aY(q,c)
n.push(new A.a0(B.P).H(q))}}return B.c.J(n," ")},
f4(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r)s=(s|B.a.P(1,B.a.m(a[r],12)))>>>0
return s},
eQ(a){var t=A.eq(a,0,A.f6(5,"count",u.S),A.G(a).c),s=t.$ti,r=new A.L(t,s.i("h(F.E)").a(new A.d8()),s.i("L<F.E,h>")).J(0,", "),q=a.length-5
return q>0?r+", and "+q+" more":r},
b2:function b2(a,b){this.a=a
this.b=b},
bI:function bI(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
ac:function ac(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
df:function df(){},
dk:function dk(){},
dl:function dl(){},
cJ:function cJ(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dh:function dh(a){this.a=a},
dd:function dd(a){this.a=a},
dc:function dc(a){this.a=a},
d8:function d8(){},
kh(){var t,s=v.G,r=new A.dg()
if(typeof r=="function")A.aZ(A.dp("Attempting to rewrap a JS function."))
t=function(a,b){return function(c,d,e){return a(b,c,d,e,arguments.length)}}(A.iB,r)
t[$.dX()]=r
s.whatchordIdentify=t
s.whatchordReady=!0},
dg:function dg(){},
la(a){throw A.E(new A.c0("Field '"+a+"' has been assigned during initialization."),new Error())},
iB(a,b,c,d,e){u.Z.a(a)
A.R(e)
if(e>=3)return a.$3(b,c,d)
if(e===2)return a.$2(b,c)
if(e===1)return a.$1(b)
return a.$0()},
eu(a,b){var t,s,r,q,p,o,n,m,l,k,j,i=b.a,h=i.length
if(h<2||b.b!==B.aK)return!1
t=a.b
s=a.a
if(t===s)return!1
r=a.e
q=r.p(0,A.al(t,s))
if(q==null||A.et(q))return!1
t=A.a(r).i("d<2>")
p=A.dD(new A.d(r,t),t.i("e.E"))
o=p.h(0,B.l)
n=p.h(0,B.m)||p.h(0,B.f)||p.h(0,B.K)||p.h(0,B.L)
m=p.h(0,B.e)||p.h(0,B.x)||p.h(0,B.u)
l=p.h(0,B.i)||p.h(0,B.z)||p.h(0,B.Z)
t=A.P(a.c)
s=!1
if(o)if(n)if(m)t=t!==B.r||l
else t=s
else t=s
else t=s
if(!t)return!1
k=B.c.gT(i)
for(t=A.i6(a),t=A.ai(t,t.r,A.a(t).c),s=t.$ti.c;t.k();){r=t.d
j=b.bc(r==null?s.a(r):r)
if(j==null||j<=k)return!1}return(h>=2?i[1]-i[0]:0)>=3},
i6(a){var t,s,r,q=A.cF(u.S)
for(t=a.e,t=new A.W(t,A.a(t).i("W<1,2>")).gq(0),s=a.a;t.k();){r=t.d
if(A.et(r.b))q.l(0,B.a.m(s+r.a,12))}return q},
et(a){var t
A:{t=B.l===a||B.K===a||B.L===a||B.m===a||B.f===a||B.x===a||B.e===a||B.u===a||B.O===a||B.Z===a||B.i===a||B.z===a
break A}return t},
am(a){var t,s,r,q,p="name",o=B.b.G(a),n=o.length
if(n===0)throw A.c(A.bF(a,p,"Empty note name"))
if(0>=n)return A.b(o,0)
t=o[0].toUpperCase()
if(!B.cb.h(0,t))throw A.c(A.bF(a,p,"Invalid note letter"))
n=B.b.E(o,1)
n=A.S(n,"\ud834\udd2a","x")
n=A.S(n,"\ud834\udd2b","bb")
n=A.S(n,"\u266f","#")
s=A.S(n,"\u266d","b")
if(s.length===0)return t
if(s==="##")s="x"
for(n=new A.aQ(s);n.k();){r=A.z(n.d)
if(r!=="b"&&r!=="#"&&r!=="x")throw A.c(A.bF(a,p,'Invalid accidental character: "'+r+'"'))}if(B.b.h(s,"x")){if(s!=="x")throw A.c(A.bF(a,p,'Invalid accidental sequence: "'+s+'"'))
return t+"x"}for(n=new A.aQ(s),q=0;n.k();){r=A.z(n.d)
if(r==="#")++q
if(r==="b")--q}if(q<-2||q>2)throw A.c(A.bF(a,p,'Accidentals beyond double-flat/double-sharp not supported: "'+s+'"'))
A:{n=""
if(-2===q){n="bb"
break A}if(-1===q){n="b"
break A}if(0===q)break A
if(1===q){n="#"
break A}if(2===q){n="x"
break A}break A}return t+n},
al(a,b){var t=B.a.m(a-b,12)
return t},
kk(a){var t,s,r,q,p,o,n,m=A.am(a)
if(0>=m.length)return A.b(m,0)
t=m[0]
A:{if("C"===t){s=0
break A}if("D"===t){s=2
break A}if("E"===t){s=4
break A}if("F"===t){s=5
break A}if("G"===t){s=7
break A}if("A"===t){s=9
break A}if("B"===t){s=11
break A}s=A.aZ(A.dJ('Unreachable: invalid note letter "'+t+'"'))}r=B.b.E(m,1)
if(r==="x")q=2
else for(p=new A.aQ(r),q=0;p.k();){o=A.z(p.d)
if(o==="#")++q
if(o==="b")--q}n=B.a.m(s+q,12)
return n},
eo(a,b,c,d,e,f){var t,s,r,q,p=A.di(b,a)
for(t=A.i2(a),s=t.length,r=0;r<s;++r){q=A.hV(a,b,c,!0,p,t[r],!0)
if(q!=null)return q}return null},
hV(a,b,c,d,e,f,g){var t,s,r,q,p,o,n,m,l,k,j=null,i=b.a,h=A.hX(a,i,f)
if(h==null)return j
if(!A.i1(a,e,h))return j
t=b.c
if(A.du(t))return j
s=A.hU(f,h)
r=A.hW(t)
if(!s.h(0,r==null?t:r))return j
q=b.d
if(!A.hZ(a,i,q,f))return j
p=c&4095
o=$.fj().p(0,t)
if(o==null)return j
n=o.b
m=n|1
l=n|o.c|1
if((p&m)!==m)return j
k=A.hY(q)
if((p&k)!==k)return j
if(!A.hT(a,i,p&l,f))return j
if((p&~(l|k))!==0)return j
A.l3(h.bf(f),t)
A.i3(h,f)
A.i_(h,f)
return new A.cO(h,f)},
hX(a,b,c){var t,s=B.a.m(b-a.a.e,12)
switch(c.a){case 0:A:{if(0===s){t=B.Q
break A}if(2===s){t=B.as
break A}if(4===s){t=B.at
break A}if(5===s){t=B.au
break A}if(7===s){t=B.av
break A}if(9===s){t=B.aw
break A}if(11===s){t=B.ax
break A}t=null
break A}return t
case 1:B:{if(0===s){t=B.Q
break B}if(2===s){t=B.as
break B}if(3===s){t=B.at
break B}if(5===s){t=B.au
break B}if(7===s){t=B.av
break B}if(8===s){t=B.aw
break B}if(10===s){t=B.ax
break B}t=null
break B}return t
case 2:C:{if(0===s){t=B.Q
break C}if(2===s){t=B.as
break C}if(3===s){t=B.at
break C}if(5===s){t=B.au
break C}if(7===s){t=B.av
break C}if(8===s){t=B.aw
break C}if(11===s){t=B.ax
break C}t=null
break C}return t}},
i1(a,b,c){var t,s,r=A.i0(b)
if(r==null)return!0
t=B.c.U(B.H,a.a.d)
s=t<0?0:t
return r===B.H[B.a.m(s+c.a,7)]},
i0(a){var t,s=A.am(a),r=s.length
if(r===0)return null
if(0>=r)return A.b(s,0)
t=s[0].toUpperCase()
return B.c.h(B.H,t)?t:null},
hW(a){var t
A:{if(B.E===a){t=B.t
break A}if(B.a0===a){t=B.D
break A}t=null
break A}return t},
hT(a,b,c,d){var t,s
for(t=0;t<12;++t){if((c&B.a.K(1,t))===0)continue
s=B.a.m(b+t,12)
if(!A.en(a,s,d))return!1}return!0},
hY(a){var t,s,r,q
for(t=A.ai(a,a.r,A.a(a).c),s=t.$ti.c,r=0;t.k();){q=t.d
r=(r|B.a.K(1,A.dr(q==null?s.a(q):q)))>>>0}return r},
hZ(a,b,c,d){var t,s,r,q
for(t=A.ai(c,c.r,A.a(c).c),s=t.$ti.c;t.k();){r=t.d
q=B.a.m(b+A.dr(r==null?s.a(r):r),12)
if(!A.en(a,q,d))return!1}return!0},
hU(a,b){var t
switch(a.a){case 0:switch(b.a){case 0:t=B.a7
break
case 1:t=B.U
break
case 2:t=B.U
break
case 3:t=B.a7
break
case 4:t=B.aT
break
case 5:t=B.U
break
case 6:t=B.ay
break
default:t=null}return t
case 1:switch(b.a){case 0:t=B.U
break
case 1:t=B.ay
break
case 2:t=B.a7
break
case 3:t=B.U
break
case 4:t=B.U
break
case 5:t=B.a7
break
case 6:t=B.aT
break
default:t=null}return t
case 2:switch(b.a){case 0:t=B.ce
break
case 1:t=B.ay
break
case 2:t=B.cd
break
case 3:t=B.U
break
case 4:t=B.cc
break
case 5:t=B.a7
break
case 6:t=B.cf
break
default:t=null}return t}},
i2(a){if(a.b===B.h)return B.bZ
return B.bU},
en(a,b,c){var t,s=B.a.m(b-a.a.e,12)
switch(c.a){case 0:A:{t=0===s||2===s||4===s||5===s||7===s||9===s||11===s
break A}break
case 1:B:{t=0===s||2===s||3===s||5===s||7===s||8===s||10===s
break B}break
case 2:C:{t=0===s||2===s||3===s||5===s||7===s||8===s||11===s
break C}break
default:t=null}return t},
i3(a,b){var t
if(b===B.aq)return a.ah(B.h)
if(b===B.ar)return a.ah(B.j)
switch(a.a){case 0:t="first"
break
case 1:t="second, diminished"
break
case 2:t="flat third, augmented"
break
case 3:t="fourth"
break
case 4:t="fifth, major"
break
case 5:t="flat sixth"
break
case 6:t="raised seventh, diminished"
break
default:t=null}return t},
i_(a,b){var t
if(b===B.aq)return a.aA(B.h)
if(b===B.ar)return a.aA(B.j)
switch(a.a){case 0:t="tonic"
break
case 1:t="supertonic"
break
case 2:t="mediant"
break
case 3:t="subdominant"
break
case 4:t="dominant"
break
case 5:t="submediant"
break
case 6:t="leading tone"
break
default:t=null}return t},
l3(a,b){var t
A:{if(B.n===b){t=a+"7"
break A}if(B.C===b){t=a+"7b5"
break A}if(B.y===b){t=a+"7#5"
break A}if(B.a3===b){t=a+"#5"
break A}if(B.a2===b){t=a+"maj7"
break A}if(B.V===b){t=a+"maj7b5"
break A}if(B.W===b){t=a+"maj7#5"
break A}if(B.M===b){t=a+"7"
break A}if(B.N===b){t=a+"7#5"
break A}if(B.S===b){t=a+"(maj7)"
break A}if(B.X===b){t=(B.b.X(a,"\xb0")?B.b.D(a,0,a.length-1):a)+"\xf87"
break A}if(B.J===b){t=a+"7"
break A}t=a
break A}return t}},B={}
var w=[A,J,B]
var $={}
A.dy.prototype={}
J.bU.prototype={
B(a,b){return a===b},
gv(a){return A.bj(a)},
j(a){return"Instance of '"+A.c2(a)+"'"},
gM(a){return A.az(A.dP(this))}}
J.bX.prototype={
j(a){return String(a)},
gv(a){return a?519018:218159},
gM(a){return A.az(u.y)},
$ia9:1,
$iH:1}
J.b9.prototype={
B(a,b){return null==b},
j(a){return"null"},
gv(a){return 0},
$ia9:1}
J.aL.prototype={$iaJ:1}
J.af.prototype={
gv(a){return 0},
j(a){return String(a)}}
J.cN.prototype={}
J.ab.prototype={}
J.ba.prototype={
j(a){var t=a[$.fi()]
if(t==null)t=a[$.dX()]
if(t==null)return this.aM(a)
return"JavaScript function for "+J.bD(t)},
$iao:1}
J.k.prototype={
l(a,b){A.G(a).c.a(b)
a.$flags&1&&A.ck(a,29)
a.push(b)},
W(a,b){A.G(a).i("e<1>").a(b)
a.$flags&1&&A.ck(a,"addAll",2)
this.aO(a,b)
return},
aO(a,b){var t,s
u.b.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.c(A.U(a))
for(s=0;s<t;++s)a.push(b[s])},
J(a,b){var t,s=A.cG(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.u(s,t,A.r(a[t]))
return s.join(b)},
ba(a){return this.J(a,"")},
be(a,b){var t,s,r
A.G(a).i("1(1,1)").a(b)
t=a.length
if(t===0)throw A.c(A.bV())
if(0>=t)return A.b(a,0)
s=a[0]
for(r=1;r<t;++r){s=b.$2(s,a[r])
if(t!==a.length)throw A.c(A.U(a))}return s},
I(a,b){if(!(b<a.length))return A.b(a,b)
return a[b]},
aK(a,b,c){var t=a.length
if(b>t)throw A.c(A.a_(b,0,t,"start",null))
if(c<b||c>t)throw A.c(A.a_(c,b,t,"end",null))
if(b===c)return A.i([],A.G(a))
return A.i(a.slice(b,c),A.G(a))},
gT(a){if(a.length>0)return a[0]
throw A.c(A.bV())},
gbb(a){var t=a.length
if(t>0)return a[t-1]
throw A.c(A.bV())},
gaG(a){var t=a.length
if(t===1){if(0>=t)return A.b(a,0)
return a[0]}if(t===0)throw A.c(A.bV())
throw A.c(A.dJ("Too many elements"))},
R(a,b){var t,s,r,q,p,o=A.G(a)
o.i("q(1,1)?").a(b)
a.$flags&2&&A.ck(a,"sort")
t=a.length
if(t<2)return
if(b==null)b=J.iP()
if(t===2){s=a[0]
r=a[1]
o=b.$2(s,r)
if(typeof o!=="number")return o.bm()
if(o>0){a[0]=r
a[1]=s}return}q=0
if(o.c.b(null))for(p=0;p<a.length;++p)if(a[p]===void 0){a[p]=null;++q}a.sort(A.k2(b,2))
if(q>0)this.b0(a,q)},
aH(a){return this.R(a,null)},
b0(a,b){var t,s=a.length
for(;t=s-1,s>0;s=t)if(a[t]===null){a[t]=void 0;--b
if(b===0)break}},
U(a,b){var t,s=a.length
if(0>=s)return-1
for(t=0;t<s;++t){if(!(t<a.length))return A.b(a,t)
if(J.Z(a[t],b))return t}return-1},
h(a,b){var t
for(t=0;t<a.length;++t)if(J.Z(a[t],b))return!0
return!1},
j(a){return A.ee(a,"[","]")},
gq(a){return new J.b1(a,a.length,A.G(a).i("b1<1>"))},
gv(a){return A.bj(a)},
gt(a){return a.length},
u(a,b,c){A.G(a).c.a(c)
a.$flags&2&&A.ck(a)
if(!(b>=0&&b<a.length))throw A.c(A.f8(a,b))
a[b]=c},
$ie:1,
$iag:1}
J.bW.prototype={
bh(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.c2(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.cA.prototype={}
J.b1.prototype={
gn(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.O(r)
throw A.c(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iy:1}
J.aI.prototype={
A(a,b){var t
A.eK(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=this.ga1(b)
if(this.ga1(a)===t)return 0
if(this.ga1(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
ga1(a){return a===0?1/a<0:a<0},
N(a,b){var t
if(b>20)throw A.c(A.a_(b,0,20,"fractionDigits",null))
t=a.toFixed(b)
if(a===0&&this.ga1(a))return"-"+t
return t},
bg(a,b){var t,s,r,q,p
if(b<2||b>36)throw A.c(A.a_(b,2,36,"radix",null))
t=a.toString(b)
s=t.length
r=s-1
if(!(r>=0))return A.b(t,r)
if(t.charCodeAt(r)!==41)return t
q=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(t)
if(q==null)A.aZ(A.es("Unexpected toString result: "+t))
s=q.length
if(1>=s)return A.b(q,1)
t=q[1]
if(3>=s)return A.b(q,3)
p=+q[3]
s=q[2]
if(s!=null){t+=s
p-=s.length}return t+B.b.aF("0",p)},
j(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gv(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
m(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
P(a,b){if(b<0)throw A.c(A.k_(b))
return b>31?0:a<<b>>>0},
K(a,b){return b>31?0:a<<b>>>0},
ar(a,b){var t
if(a>0)t=this.b1(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
b1(a,b){return b>31?0:a>>>b},
gM(a){return A.az(u.H)},
$ia3:1,
$iak:1,
$iK:1}
J.b8.prototype={
gM(a){return A.az(u.S)},
$ia9:1,
$iq:1}
J.bY.prototype={
gM(a){return A.az(u.i)},
$ia9:1}
J.ae.prototype={
ae(a,b,c){var t=b.length
if(c>t)throw A.c(A.a_(c,0,t,null,null))
return new A.cg(b,a,c)},
aw(a,b){return this.ae(a,b,0)},
X(a,b){var t=b.length,s=a.length
if(t>s)return!1
return b===this.E(a,s-t)},
L(a,b,c){return A.l8(a,b,c,0)},
aI(a,b){var t
if(typeof b=="string")return A.i(a.split(b),u.s)
else{if(b instanceof A.aK){t=b.e
t=!(t==null?b.e=b.aQ():t)}else t=!1
if(t)return A.i(a.split(b.b),u.s)
else return this.aS(a,b)}},
aS(a,b){var t,s,r,q,p,o,n=A.i([],u.s)
for(t=J.dZ(b,a),t=t.gq(t),s=0,r=1;t.k();){q=t.gn()
p=q.ga4()
o=q.ga0()
r=o-p
if(r===0&&s===p)continue
B.c.l(n,this.D(a,s,p))
s=o}if(s<a.length||r>0)B.c.l(n,this.E(a,s))
return n},
a5(a,b){var t=b.length
if(t>a.length)return!1
return b===a.substring(0,t)},
D(a,b,c){return a.substring(b,A.hQ(b,c,a.length))},
E(a,b){return this.D(a,b,null)},
G(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.b(q,0)
if(q.charCodeAt(0)===133){t=J.hG(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.b(q,s)
r=q.charCodeAt(s)===133?J.hH(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
aF(a,b){var t,s
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.c(B.b2)
for(t=a,s="";;){if((b&1)===1)s=t+s
b=b>>>1
if(b===0)break
t+=t}return s},
U(a,b){var t=a.indexOf(b,0)
return t},
h(a,b){return A.l5(a,b,0)},
A(a,b){var t
A.Y(b)
if(a===b)t=0
else t=a<b?-1:1
return t},
j(a){return a},
gv(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gM(a){return A.az(u.N)},
gt(a){return a.length},
$ia9:1,
$ia3:1,
$icM:1,
$ih:1}
A.c0.prototype={
j(a){return"LateInitializationError: "+this.a}}
A.cQ.prototype={}
A.b7.prototype={}
A.F.prototype={
gq(a){var t=this
return new A.bf(t,t.gt(t),A.a(t).i("bf<F.E>"))},
J(a,b){var t,s,r,q=this,p=q.gt(q)
if(b.length!==0){if(p===0)return""
t=A.r(q.I(0,0))
if(p!==q.gt(q))throw A.c(A.U(q))
for(s=t,r=1;r<p;++r){s=s+b+A.r(q.I(0,r))
if(p!==q.gt(q))throw A.c(A.U(q))}return s.charCodeAt(0)==0?s:s}else{for(r=0,s="";r<p;++r){s+=A.r(q.I(0,r))
if(p!==q.gt(q))throw A.c(A.U(q))}return s.charCodeAt(0)==0?s:s}}}
A.bq.prototype={
gaT(){var t=this.a.length,s=this.c
if(s>t)return t
return s},
gb2(){var t=this.a.length,s=this.b
if(s>t)return t
return s},
gt(a){var t,s=this.a.length,r=this.b
if(r>=s)return 0
t=this.c
if(t>=s)return s-r
return t-r},
I(a,b){var t=this,s=t.gb2()+b,r=t.gaT()
if(s>=r)throw A.c(A.dw(b,t.gt(0),t,"index"))
r=t.a
if(!(s<r.length))return A.b(r,s)
return r[s]}}
A.bf.prototype={
gn(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=r.gt(r)
if(s.b!==q)throw A.c(A.U(r))
t=s.c
if(t>=q){s.d=null
return!1}s.d=r.I(0,t);++s.c
return!0},
$iy:1}
A.L.prototype={
gt(a){return J.bC(this.a)},
I(a,b){return this.b.$1(J.fz(this.a,b))}}
A.as.prototype={
gq(a){return new A.bu(J.dn(this.a),this.b,this.$ti.i("bu<1>"))}}
A.bu.prototype={
k(){var t,s
for(t=this.a,s=this.b;t.k();)if(s.$1(t.gn()))return!0
return!1},
gn(){return this.a.gn()},
$iy:1}
A.aV.prototype={$r:"+midi,name,pc(1,2,3)",$s:1}
A.bv.prototype={$r:"+addCount,alterationCount,naturalCount,totalCount(1,2,3,4)",$s:2}
A.b6.prototype={
gag(a){return this.gt(this)===0},
j(a){return A.dF(this)},
$ia5:1}
A.aH.prototype={
gt(a){return this.b.length},
gaZ(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
S(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
p(a,b){if(!this.S(b))return null
return this.b[this.a[b]]},
Y(a,b){var t,s,r,q
this.$ti.i("~(1,2)").a(b)
t=this.gaZ()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])}}
A.au.prototype={
gn(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t=this,s=t.c
if(s>=t.b){t.d=null
return!1}t.d=t.a[s]
t.c=s+1
return!0},
$iy:1}
A.aG.prototype={
l(a,b){A.a(this).c.a(b)
A.hC()}}
A.an.prototype={
gt(a){return this.b},
gq(a){var t,s=this,r=s.$keys
if(r==null){r=Object.keys(s.a)
s.$keys=r}t=r
return new A.au(t,t.length,s.$ti.i("au<1>"))},
h(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.J.prototype={
gt(a){return this.a.length},
gq(a){var t=this.a
return new A.au(t,t.length,this.$ti.i("au<1>"))},
aX(){var t,s,r,q,p=this,o=p.$map
if(o==null){o=new A.bb(p.$ti.i("bb<1,1>"))
for(t=p.a,s=t.length,r=0;r<t.length;t.length===s||(0,A.O)(t),++r){q=t[r]
o.u(0,q,q)}p.$map=o}return o},
h(a,b){return this.aX().S(b)}}
A.bm.prototype={}
A.cR.prototype={
F(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.bi.prototype={
j(a){return"Null check operator used on a null value"}}
A.bZ.prototype={
j(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.c8.prototype={
j(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.cL.prototype={
j(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.ad.prototype={
j(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.fg(s==null?"unknown":s)+"'"},
$iao:1,
gbl(){return this},
$C:"$1",
$R:1,
$D:null}
A.bN.prototype={$C:"$0",$R:0}
A.bO.prototype={$C:"$2",$R:2}
A.c6.prototype={}
A.c4.prototype={
j(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.fg(t)+"'"}}
A.aE.prototype={
B(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.aE))return!1
return this.$_target===b.$_target&&this.a===b.a},
gv(a){return(A.dV(this.a)^A.bj(this.$_target))>>>0},
j(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.c2(this.a)+"'")}}
A.c3.prototype={
j(a){return"RuntimeError: "+this.a}}
A.V.prototype={
gt(a){return this.a},
gag(a){return this.a===0},
S(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){s=this.c
if(s==null)return!1
return s[a]!=null}else return this.b6(a)},
b6(a){var t=this.d
if(t==null)return!1
return this.a_(t[this.Z(a)],a)>=0},
W(a,b){A.a(this).i("a5<1,2>").a(b).Y(0,new A.cB(this))},
p(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.b7(b)},
b7(a){var t,s,r=this.d
if(r==null)return null
t=r[this.Z(a)]
s=this.a_(t,a)
if(s<0)return null
return t[s].b},
u(a,b,c){var t,s,r=this,q=A.a(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.ai(t==null?r.b=r.ac():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.ai(s==null?r.c=r.ac():s,b,c)}else r.b9(b,c)},
b9(a,b){var t,s,r,q,p=this,o=A.a(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.ac()
s=p.Z(a)
r=t[s]
if(r==null)t[s]=[p.ad(a,b)]
else{q=p.a_(r,a)
if(q>=0)r[q].b=b
else r.push(p.ad(a,b))}},
bd(a,b){var t,s,r=this,q=A.a(r)
q.c.a(a)
q.i("2()").a(b)
if(r.S(a)){t=r.p(0,a)
return t==null?q.y[1].a(t):t}s=b.$0()
r.u(0,a,s)
return s},
aB(a,b){if((b&0x3fffffff)===b)return this.b_(this.c,b)
else return this.b8(b)},
b8(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.Z(a)
s=o[t]
r=p.a_(s,a)
if(r<0)return null
q=s.splice(r,1)[0]
p.av(q)
if(s.length===0)delete o[t]
return q.b},
Y(a,b){var t,s,r=this
A.a(r).i("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.c(A.U(r))
t=t.c}},
ai(a,b,c){var t,s=A.a(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.ad(b,c)
else t.b=c},
b_(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.av(t)
delete a[b]
return t.b},
ao(){this.r=this.r+1&1073741823},
ad(a,b){var t=this,s=A.a(t),r=new A.cE(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.ao()
return r},
av(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.ao()},
Z(a){return J.t(a)&1073741823},
a_(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.Z(a[s].a,b))return s
return-1},
j(a){return A.dF(this)},
ac(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$idB:1}
A.cB.prototype={
$2(a,b){var t=this.a,s=A.a(t)
t.u(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.a(this.a).i("~(1,2)")}}
A.cE.prototype={}
A.a4.prototype={
gt(a){return this.a.a},
gq(a){var t=this.a
return new A.ap(t,t.r,t.e,this.$ti.i("ap<1>"))}}
A.ap.prototype={
gn(){return this.d},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.U(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iy:1}
A.d.prototype={
gt(a){return this.a.a},
gq(a){var t=this.a
return new A.be(t,t.r,t.e,this.$ti.i("be<1>"))}}
A.be.prototype={
gn(){return this.d},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.U(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.b
s.c=t.c
return!0}},
$iy:1}
A.W.prototype={
gt(a){return this.a.a},
gq(a){var t=this.a
return new A.bd(t,t.r,t.e,this.$ti.i("bd<1,2>"))}}
A.bd.prototype={
gn(){var t=this.d
t.toString
return t},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.U(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.aq(t.a,t.b,s.$ti.i("aq<1,2>"))
s.c=t.c
return!0}},
$iy:1}
A.bb.prototype={
Z(a){return A.k1(a)&1073741823},
a_(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.Z(a[s].a,b))return s
return-1}}
A.a1.prototype={
j(a){return this.au(!1)},
au(a){var t,s,r,q,p,o=this.aV(),n=this.ab(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.b(n,r)
p=n[r]
m=a?m+A.ej(p):m+A.r(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
aV(){var t,s=this.$s
while($.d_.length<=s)B.c.l($.d_,null)
t=$.d_[s]
if(t==null){t=this.aP()
B.c.u($.d_,s,t)}return t},
aP(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=u.K,k=J.cz(m,l)
for(t=0;t<m;++t)k[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.c.u(k,r,s[t])}}return A.dE(k,l)}}
A.aT.prototype={
ab(){return[this.a,this.b,this.c]},
B(a,b){var t=this
if(b==null)return!1
return b instanceof A.aT&&t.$s===b.$s&&J.Z(t.a,b.a)&&J.Z(t.b,b.b)&&J.Z(t.c,b.c)},
gv(a){var t=this
return A.a6(t.$s,t.a,t.b,t.c,B.d,B.d)}}
A.aU.prototype={
ab(){return this.a},
B(a,b){if(b==null)return!1
return b instanceof A.aU&&this.$s===b.$s&&A.ig(this.a,b.a)},
gv(a){return A.a6(this.$s,A.dG(this.a),B.d,B.d,B.d,B.d)}}
A.aK.prototype={
j(a){return"RegExp/"+this.a+"/"+this.b.flags},
gap(){var t=this,s=t.c
if(s!=null)return s
s=t.b
return t.c=A.eg(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,"g")},
aQ(){var t,s=this.a
if(!B.b.h(s,"("))return!1
t=this.b.unicode?"u":""
return new RegExp("(?:)|"+s,t).exec("").length>1},
ae(a,b,c){var t=b.length
if(c>t)throw A.c(A.a_(c,0,t,null,null))
return new A.ca(this,b,c)},
aw(a,b){return this.ae(0,b,0)},
aU(a,b){var t,s=this.gap()
if(s==null)s=A.dN(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.cf(t)},
$icM:1,
$ihR:1}
A.cf.prototype={
ga4(){return this.b.index},
ga0(){var t=this.b
return t.index+t[0].length},
$iaO:1,
$ibl:1}
A.ca.prototype={
gq(a){return new A.cb(this.a,this.b,this.c)}}
A.cb.prototype={
gn(){var t=this.d
return t==null?u.e.a(t):t},
k(){var t,s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
t=n.c
s=m.length
if(t<=s){r=n.a
q=r.aU(m,t)
if(q!=null){n.d=q
p=q.ga0()
if(q.b.index===p){t=!1
if(r.b.unicode){r=n.c
o=r+1
if(o<s){if(!(r>=0&&r<s))return A.b(m,r)
r=m.charCodeAt(r)
if(r>=55296&&r<=56319){if(!(o>=0))return A.b(m,o)
t=m.charCodeAt(o)
t=t>=56320&&t<=57343}}}p=(t?p+1:p)+1}n.c=p
return!0}}n.b=n.d=null
return!1},
$iy:1}
A.c5.prototype={
ga0(){return this.a+this.c.length},
$iaO:1,
ga4(){return this.a}}
A.cg.prototype={
gq(a){return new A.ch(this.a,this.b,this.c)}}
A.ch.prototype={
k(){var t,s,r=this,q=r.c,p=r.b,o=p.length,n=r.a,m=n.length
if(q+o>m){r.d=null
return!1}t=n.indexOf(p,q)
if(t<0){r.c=m+1
r.d=null
return!1}s=t+o
r.d=new A.c5(t,p)
r.c=s===r.c?s+1:s
return!0},
gn(){var t=this.d
t.toString
return t},
$iy:1}
A.X.prototype={
i(a){return A.bB(v.typeUniverse,this,a)},
V(a){return A.eG(v.typeUniverse,this,a)}}
A.cd.prototype={}
A.ci.prototype={
j(a){return A.M(this.a,null)}}
A.cc.prototype={
j(a){return this.a}}
A.bx.prototype={}
A.av.prototype={
gq(a){var t=this,s=new A.aw(t,t.r,A.a(t).i("aw<1>"))
s.c=t.e
return s},
gt(a){return this.a},
h(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.g.a(t[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){s=this.c
if(s==null)return!1
return u.g.a(s[b])!=null}else return this.aR(b)},
aR(a){var t=this.d
if(t==null)return!1
return this.al(t[this.ak(a)],a)>=0},
l(a,b){var t,s,r=this
A.a(r).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.aj(t==null?r.b=A.dK():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.aj(s==null?r.c=A.dK():s,b)}else return r.aN(b)},
aN(a){var t,s,r,q=this
A.a(q).c.a(a)
t=q.d
if(t==null)t=q.d=A.dK()
s=q.ak(a)
r=t[s]
if(r==null)t[s]=[q.a7(a)]
else{if(q.al(r,a)>=0)return!1
r.push(q.a7(a))}return!0},
aj(a,b){A.a(this).c.a(b)
if(u.g.a(a[b])!=null)return!1
a[b]=this.a7(b)
return!0},
a7(a){var t=this,s=new A.ce(A.a(t).c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
ak(a){return J.t(a)&1073741823},
al(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.Z(a[s].a,b))return s
return-1}}
A.ce.prototype={}
A.aw.prototype={
gn(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.c(A.U(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.i("1?").a(s.a)
t.c=s.b
return!0}},
$iy:1}
A.aN.prototype={
Y(a,b){var t,s,r,q=this,p=A.a(q)
p.i("~(1,2)").a(b)
for(t=new A.ap(q,q.r,q.e,p.i("ap<1>")),p=p.y[1];t.k();){s=t.d
r=q.p(0,s)
b.$2(s,r==null?p.a(r):r)}},
gt(a){return this.a},
gag(a){return this.a===0},
j(a){return A.dF(this)},
$ia5:1}
A.cH.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.r(a)
s.a=(s.a+=t)+": "
t=A.r(b)
s.a+=t},
$S:4}
A.a8.prototype={
W(a,b){var t
A.a(this).i("e<1>").a(b)
for(t=b.gq(b);t.k();)this.l(0,t.gn())},
j(a){return A.ee(this,"{","}")},
az(a,b){var t
A.a(this).i("H(1)").a(b)
for(t=this.gq(this);t.k();)if(b.$1(t.gn()))return!0
return!1},
$ie:1,
$ibn:1}
A.bw.prototype={}
A.bP.prototype={}
A.bR.prototype={}
A.bc.prototype={
j(a){var t=A.bS(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.c_.prototype={
j(a){return"Cyclic error in JSON stringify"}}
A.cC.prototype={
b3(a,b){var t=A.i8(a,this.gb4().b,null)
return t},
gb4(){return B.bE}}
A.cD.prototype={}
A.cX.prototype={
aE(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.b.D(a,s,r)
s=r+1
p=A.z(92)
t.a+=p
p=A.z(117)
t.a+=p
p=A.z(100)
t.a+=p
p=q>>>8&15
p=A.z(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.z(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.z(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.b.D(a,s,r)
s=r+1
p=A.z(92)
t.a+=p
switch(q){case 8:p=A.z(98)
t.a+=p
break
case 9:p=A.z(116)
t.a+=p
break
case 10:p=A.z(110)
t.a+=p
break
case 12:p=A.z(102)
t.a+=p
break
case 13:p=A.z(114)
t.a+=p
break
default:p=A.z(117)
t.a+=p
p=A.z(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.z(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.z(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.b.D(a,s,r)
s=r+1
p=A.z(92)
t.a+=p
p=A.z(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.b.D(a,s,n)},
a6(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.c(new A.c_(a,null))}B.c.l(t,a)},
a3(a){var t,s,r,q,p=this
if(p.aD(a))return
p.a6(a)
try{t=p.b.$1(a)
if(!p.aD(t)){r=A.eh(a,null,p.gaq())
throw A.c(r)}r=p.a
if(0>=r.length)return A.b(r,-1)
r.pop()}catch(q){s=A.dW(q)
r=A.eh(a,s,p.gaq())
throw A.c(r)}},
aD(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.F.j(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.aE(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.a6(a)
r.bj(a)
t=r.a
if(0>=t.length)return A.b(t,-1)
t.pop()
return!0}else if(u.J.b(a)){r.a6(a)
s=r.bk(a)
t=r.a
if(0>=t.length)return A.b(t,-1)
t.pop()
return s}else return!1},
bj(a){var t,s,r=this.c
r.a+="["
t=a.length
if(t!==0){if(0>=t)return A.b(a,0)
this.a3(a[0])
for(s=1;s<a.length;++s){r.a+=","
this.a3(a[s])}}r.a+="]"},
bk(a){var t,s,r,q,p,o,n=this,m={}
if(a.gag(a)){n.c.a+="{}"
return!0}t=a.gt(a)*2
s=A.cG(t,null,!1,u.X)
r=m.a=0
m.b=!0
a.Y(0,new A.cY(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.aE(A.Y(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.b(s,o)
n.a3(s[o])}q.a+="}"
return!0}}
A.cY.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.c.u(t,s.a++,a)
B.c.u(t,s.a++,b)},
$S:4}
A.cW.prototype={
gaq(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.cU.prototype={
j(a){return this.C()}}
A.w.prototype={}
A.bG.prototype={
j(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bS(t)
return"Assertion failed"}}
A.bs.prototype={}
A.T.prototype={
ga9(){return"Invalid argument"+(!this.a?"(s)":"")},
ga8(){return""},
j(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.ga9()+r+p
if(!t.a)return o
return o+t.ga8()+": "+A.bS(t.gaf())},
gaf(){return this.b}}
A.bk.prototype={
gaf(){return A.eL(this.b)},
ga9(){return"RangeError"},
ga8(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.r(r):""
else if(r==null)t=": Not greater than or equal to "+A.r(s)
else if(r>s)t=": Not in inclusive range "+A.r(s)+".."+A.r(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.r(s)
return t}}
A.bT.prototype={
gaf(){return A.R(this.b)},
ga9(){return"RangeError"},
ga8(){if(A.R(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gt(a){return this.f}}
A.bt.prototype={
j(a){return"Unsupported operation: "+this.a}}
A.bp.prototype={
j(a){return"Bad state: "+this.a}}
A.bQ.prototype={
j(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bS(t)+"."}}
A.c1.prototype={
j(a){return"Out of Memory"},
$iw:1}
A.bo.prototype={
j(a){return"Stack Overflow"},
$iw:1}
A.cV.prototype={
j(a){return"Exception: "+this.a}}
A.cy.prototype={
j(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException",r=this.b
if(r.length>78)r=B.b.D(r,0,75)+"..."
return s+"\n"+r}}
A.e.prototype={
bi(a,b){var t=A.a(this)
return new A.as(this,t.i("H(e.E)").a(b),t.i("as<e.E>"))},
h(a,b){var t
for(t=this.gq(this);t.k();)if(J.Z(t.gn(),b))return!0
return!1},
b5(a,b,c,d){var t,s
d.a(b)
A.a(this).V(d).i("1(1,e.E)").a(c)
for(t=this.gq(this),s=b;t.k();)s=c.$2(s,t.gn())
return s},
gt(a){var t,s=this.gq(this)
for(t=0;s.k();)++t
return t},
gT(a){var t=this.gq(this)
if(!t.k())throw A.c(A.bV())
return t.gn()},
I(a,b){var t,s
A.dH(b,"index")
t=this.gq(this)
for(s=b;t.k();){if(s===0)return t.gn();--s}throw A.c(A.dw(b,b-s,this,"index"))},
j(a){return A.hD(this,"(",")")}}
A.aq.prototype={
j(a){return"MapEntry("+A.r(this.a)+": "+A.r(this.b)+")"}}
A.bh.prototype={
gv(a){return A.p.prototype.gv.call(this,0)},
j(a){return"null"}}
A.p.prototype={$ip:1,
B(a,b){return this===b},
gv(a){return A.bj(this)},
j(a){return"Instance of '"+A.c2(this)+"'"},
gM(a){return A.kb(this)},
toString(){return this.j(this)}}
A.aQ.prototype={
gn(){return this.d},
k(){var t,s,r,q=this,p=q.b=q.c,o=q.a,n=o.length
if(p===n){q.d=-1
return!1}if(!(p<n))return A.b(o,p)
t=o.charCodeAt(p)
s=p+1
if((t&64512)===55296&&s<n){if(!(s<n))return A.b(o,s)
r=o.charCodeAt(s)
if((r&64512)===56320){q.c=s+1
q.d=65536+((t&1023)<<10)+(r&1023)
return!0}}q.c=s
q.d=t
return!0},
$iy:1}
A.aS.prototype={
gt(a){return this.a.length},
j(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ii4:1}
A.a2.prototype={}
A.cl.prototype={
$1(a){return A.fW(u.G.a(a),this.a)},
$S:2}
A.cP.prototype={
j(a){var t,s=this.b,r=s>=0?"+"+B.F.N(s,2):B.F.N(s,2)
s=this.c
t=this.a+" "
return s==null?t+r:t+r+" ("+s+")"}}
A.co.prototype={
$1(a){return u.o.a(a).a},
$S:5}
A.cm.prototype={
$1(a){return u.o.a(a).a},
$S:5}
A.cn.prototype={
$4$detail$intervals(a,b,c,d){var t=this.a
if(t!=null)B.c.l(t,new A.cP(a,b,c))},
$2(a,b){return this.$4$detail$intervals(a,b,null,null)},
$3$detail(a,b,c){return this.$4$detail$intervals(a,b,c,null)},
$S:11}
A.at.prototype={}
A.d1.prototype={}
A.ar.prototype={}
A.cp.prototype={
$2(a,b){var t,s,r,q
A.R(a)
A.R(b)
t=this.a
s=t.length
if(!(b>=0&&b<s))return A.b(t,b)
r=t[b]
if(!(a>=0&&a<s))return A.b(t,a)
t=t[a]
q=B.F.A(r.b,t.b)
if(q!==0)return q
return B.a.A(t.a.a,r.a.a)},
$S:1}
A.b5.prototype={}
A.d6.prototype={
$2(a,b){var t=u.G
t.a(a)
t.a(b)
return B.a.A(A.b3(a),A.b3(b))},
$S:3}
A.d7.prototype={
$1(a){return u.G.a(a).b},
$S:6}
A.bg.prototype={}
A.d9.prototype={
$1(a){u.G.a(a)
return a!==B.I&&a!==B.o&&a!==B.p&&a!==B.w},
$S:2}
A.da.prototype={
$2(a,b){var t,s,r=!0
if(b.a){t=a.a
if(t.c===B.S){r=t.d
r=r.a!==1||!r.h(0,B.w)}}if(r)return!1
r=a.a
s=A.eo(this.a,r,r.f,!0,null,!0)
r=s==null
if((r?null:s.a)===B.Q){t=(r?null:s.b)===B.aR
r=t}else r=!1
return r},
$S:7}
A.db.prototype={
$2(a,b){var t
if(b.z){t=a.a.d
t=t.a===1&&t.h(0,B.R)}else t=!1
return t},
$S:7}
A.bE.prototype={
B(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.bE&&s.a.B(0,b.a)&&s.b.a===b.b.a&&s.c.a===b.c.a
else t=!0
return t},
gv(a){return A.a6(this.a,this.b.a,this.c.a,B.d,B.d,B.d)}}
A.I.prototype={
j(a){return"ChordCandidate(score="+A.r(this.b)+", "+this.a.j(0)+")"}}
A.o.prototype={
C(){return"ChordExtension."+this.b}}
A.bJ.prototype={
j(a){var t=this
return"ChordIdentity(root="+t.a+", bass="+t.b+", quality="+t.c.j(0)+", ext="+t.d.j(0)+", roles="+t.e.j(0)+")"},
B(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.bJ&&b.a===s.a&&b.b===s.b&&b.c===s.c&&A.hk(b.d,s.d,u.G)&&A.hi(b.e,s.e,u.S,u.u)&&b.f===s.f
else t=!0
return t},
gv(a){var t=this
return A.a6(t.a,t.b,t.c,A.hl(t.d,u.G),A.hj(t.e,u.S,u.u),t.f)}}
A.l.prototype={
C(){return"ChordQualityToken."+this.b}}
A.bM.prototype={
C(){return"ChordQualityFamily."+this.b}}
A.bK.prototype={
j(a){return"ChordInput(mask=0x"+B.a.bg(this.a,16)+", bass="+this.b+", n="+this.c+")"},
B(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.bK&&b.a===s.a&&b.b===s.b&&b.c===s.c
else t=!0
return t},
gv(a){return A.a6(this.a,this.b,this.c,B.d,B.d,B.d)}}
A.n.prototype={
C(){return"ChordToneRole."+this.b}}
A.C.prototype={}
A.cK.prototype={}
A.c9.prototype={
C(){return"VoicingRegisters."+this.b}}
A.aP.prototype={
bc(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(B.a.m(q,12)===a)return q}return null},
j(a){return"ObservedVoicing("+A.r(this.a)+", "+this.b.b+")"},
B(a,b){var t
if(b==null)return!1
if(this!==b)t=b instanceof A.aP&&b.b===this.b&&A.hN(b.a,this.a)
else t=!0
return t},
gv(a){return A.a6(A.dG(this.a),this.b,B.d,B.d,B.d,B.d)}}
A.a7.prototype={
C(){return"ScaleDegree."+this.b},
aC(a){var t
if(a===B.h){switch(this.a){case 0:t="I"
break
case 1:t="ii"
break
case 2:t="iii"
break
case 3:t="IV"
break
case 4:t="V"
break
case 5:t="vi"
break
case 6:t="vii\xb0"
break
default:t=null}return t}switch(this.a){case 0:t="i"
break
case 1:t="ii\xb0"
break
case 2:t="\u266dIII"
break
case 3:t="iv"
break
case 4:t="v"
break
case 5:t="\u266dVI"
break
case 6:t="\u266dVII"
break
default:t=null}return t},
bf(a){var t=null
switch(a.a){case 0:t=this.aC(B.h)
break
case 1:t=this.aC(B.j)
break
case 2:switch(this.a){case 0:t="i"
break
case 1:t="ii\xb0"
break
case 2:t="\u266dIII+"
break
case 3:t="iv"
break
case 4:t="V"
break
case 5:t="\u266dVI"
break
case 6:t="vii\xb0"
break}break}return t},
ah(a){var t
if(a===B.h){switch(this.a){case 0:t="first"
break
case 1:t="second"
break
case 2:t="third"
break
case 3:t="fourth"
break
case 4:t="fifth"
break
case 5:t="sixth"
break
case 6:t="seventh, diminished"
break
default:t=null}return t}switch(this.a){case 0:t="first"
break
case 1:t="second, diminished"
break
case 2:t="flat third"
break
case 3:t="fourth"
break
case 4:t="fifth"
break
case 5:t="flat sixth"
break
case 6:t="flat seventh"
break
default:t=null}return t},
aA(a){var t
switch(this.a){case 0:t="tonic"
break
case 1:t="supertonic"
break
case 2:t="mediant"
break
case 3:t="subdominant"
break
case 4:t="dominant"
break
case 5:t="submediant"
break
case 6:t=a===B.h?"leading tone":"subtonic"
break
default:t=null}return t}}
A.aR.prototype={
C(){return"ScaleDegreeSource."+this.b}}
A.cO.prototype={}
A.c7.prototype={
C(){return"TonalityMode."+this.b}}
A.j.prototype={
O(a){var t=A.eo(this,a,a.f,!0,null,!0)
return t==null?null:t.a},
B(a,b){var t
if(b==null)return!1
if(this!==b)t=b instanceof A.j&&b.a===this.a&&b.b===this.b
else t=!0
return t},
gv(a){return A.a6(this.a,this.b,B.d,B.d,B.d,B.d)},
j(a){var t=this.a.c
return this.b===B.h?t+" major":t+" minor"}}
A.x.prototype={
C(){return"Tonic."+this.b}}
A.m.prototype={}
A.cx.prototype={
$1(a){return(this.a&B.a.K(1,B.a.m(a,12)))>>>0!==0},
$S:12}
A.cv.prototype={
$2(a,b){if(this.a.$1(a))this.b.u(0,a,b)},
$S:8}
A.cw.prototype={
$2(a,b){var t
if(!this.a.$1(a))return
t=this.b
if(t.S(a))return
t.u(0,a,b)},
$S:8}
A.de.prototype={
$1(a){return this.a.h(0,a)},
$S:9}
A.cT.prototype={}
A.d0.prototype={}
A.bL.prototype={
C(){return"ChordNotationStyle."+this.b}}
A.cI.prototype={
C(){return"NoteNameSystem."+this.b}}
A.dv.prototype={
j(a){var t=this.a+this.b,s=this.c
return s==null?t:t+" / "+s}}
A.cq.prototype={
$1(a){u.G.a(a)
if(!A.cr(a))return!0
if(A.dr(a)!==this.a)return!0
return!1},
$S:2}
A.cs.prototype={
C(){return"ChordLongFormAccidentalStyle."+this.b}}
A.d5.prototype={
$2(a,b){var t=u.G
t.a(a)
t.a(b)
return B.a.A(A.b3(a),A.b3(b))},
$S:3}
A.ct.prototype={
$2(a,b){var t=u.G
t.a(a)
t.a(b)
return B.a.A(A.b3(a),A.b3(b))},
$S:3}
A.cu.prototype={
$1(a){return A.e7(u.G.a(a))},
$S:6}
A.b4.prototype={
C(){return"ChordQualityLabelForm."+this.b}}
A.a0.prototype={
H(a){var t,s,r=A.ew(a)
if(r==null)return A.dm(a)
t=A.dm(r.b)
switch(this.a.a){case 0:s=r.a+t
break
case 1:s=this.an(r)
break
case 2:s=this.am(r.a)+t
break
default:s=null}return s},
aJ(a,b){var t,s=this,r=A.ew(a)
if(r==null)return B.b.G(a)
switch(s.a.a){case 0:t=s.aY(r,!1)
break
case 1:t=s.an(r)
break
case 2:t=s.aW(r,!1)
break
default:t=null}return t},
an(a){var t,s,r=a.a
if(r==="B"){t=a.b
A:{if(""===t){r="H"
break A}if("b"===t){r="B"
break A}if("bb"===t){r="H\ud834\udd2b"
break A}if("#"===t){r="H\u266f"
break A}if("##"===t||"x"===t){r="H\ud834\udd2a"
break A}r="H"+A.dm(t)
break A}return r}s=a.b
B:{if(""===s)break B
if("#"===s){r+="is"
break B}if("##"===s||"x"===s){r+="isis"
break B}if("b"===s){r+=this.aa(r)
break B}if("bb"===s){r=r+this.aa(r)+this.aa(r)
break B}r+=A.dm(s)
break B}return r},
aa(a){var t
A:{if("A"===a||"E"===a){t="s"
break A}t="es"
break A}return t},
aY(a,b){var t,s=a.a,r=a.b
A:{if(""===r){t=s
break A}if("#"===r){t=s+" sharp"
break A}if("b"===r){t=s+" flat"
break A}if("##"===r||"x"===r){t=s+" double sharp"
break A}if("bb"===r){t=s+" double flat"
break A}t=s+" "+r
break A}return t},
aW(a,b){var t,s=this.am(a.a),r=a.b
A:{if(""===r){t=s
break A}if("#"===r){t=s+" sharp"
break A}if("b"===r){t=s+" flat"
break A}if("##"===r||"x"===r){t=s+" double sharp"
break A}if("bb"===r){t=s+" double flat"
break A}t=s+" "+r
break A}return t},
am(a){var t
A:{if("C"===a){t="Do"
break A}if("D"===a){t="Re"
break A}if("E"===a){t="Mi"
break A}if("F"===a){t="Fa"
break A}if("G"===a){t="Sol"
break A}if("A"===a){t="La"
break A}if("B"===a){t="Si"
break A}t=a
break A}return t}}
A.cZ.prototype={}
A.b2.prototype={
C(){return"CandidateClass."+this.b}}
A.bI.prototype={
a2(){var t=this
return A.dC(["rank",t.a,"symbol",t.b,"academicName",t.c,"chordTones",t.d,"alsoPlayedNotes",t.e,"score",A.f9(B.F.N(t.f,2)),"deltaBest",A.f9(B.F.N(t.r,2)),"class",A.fE(t.w)],u.N,u.X)}}
A.ac.prototype={
a2(){var t,s,r,q=this,p=u.N,o=u.X,n=A.dC(["notes",q.b,"bass",q.c,"key",q.d],p,o),m=A.i([],u.d)
for(t=q.e,s=t.length,r=0;r<t.length;t.length===s||(0,A.O)(t),++r)m.push(t[r].a2())
return A.dC(["ok",q.a,"input",n,"candidates",m,"warnings",q.f,"errors",q.r],p,o)}}
A.df.prototype={
$2(a,b){A.R(a)
A.R(b)
return a<b?a:b},
$S:1}
A.dk.prototype={
$1(a){return B.b.G(A.Y(a))},
$S:10}
A.dl.prototype={
$1(a){return A.Y(a).length!==0},
$S:9}
A.cJ.prototype={}
A.dh.prototype={
$0(){return this.a},
$S:13}
A.dd.prototype={
$2(a,b){var t,s,r
A.R(a)
A.R(b)
t=this.a
s=t.p(0,a)
s.toString
s=A.ea(s)
t=t.p(0,b)
t.toString
r=B.a.A(s,A.ea(t))
return r!==0?r:B.a.A(a,b)},
$S:1}
A.dc.prototype={
$2(a,b){return(A.R(a)|B.a.P(1,B.a.m(this.a.a+A.R(b),12)))>>>0},
$S:1}
A.d8.prototype={
$1(a){A.Y(a)
return'"'+(a.length<=32?a:B.b.D(a,0,32)+"...")+'"'},
$S:10}
A.dg.prototype={
$3(a,b,c){A.Y(a)
A.Y(b)
return B.b1.b3(A.kd(a,b,A.Y(c)==="symbolic"?B.ah:B.b7).a2(),null)},
$S:14};(function aliases(){var t=J.af.prototype
t.aM=t.j
t=A.e.prototype
t.aL=t.bi})();(function installTearOffs(){var t=hunkHelpers._static_2,s=hunkHelpers._static_1,r=hunkHelpers.installStaticTearOff
t(J,"iP","hF",15)
s(A,"k4","iE",16)
r(A,"k0",5,null,["$5"],["kl"],0,0)
r(A,"kE",5,null,["$5"],["jn"],0,0)
r(A,"kW",5,null,["$5"],["jF"],0,0)
r(A,"kw",5,null,["$5"],["jf"],0,0)
r(A,"kn",5,null,["$5"],["j6"],0,0)
r(A,"kB",5,null,["$5"],["jk"],0,0)
r(A,"kt",5,null,["$5"],["jc"],0,0)
r(A,"kq",5,null,["$5"],["j9"],0,0)
r(A,"ks",5,null,["$5"],["jb"],0,0)
r(A,"kM",5,null,["$5"],["jv"],0,0)
r(A,"kp",5,null,["$5"],["j8"],0,0)
r(A,"l2",5,null,["$5"],["jM"],0,0)
r(A,"kV",5,null,["$5"],["jE"],0,0)
r(A,"kZ",5,null,["$5"],["jI"],0,0)
r(A,"kU",5,null,["$5"],["jD"],0,0)
r(A,"ku",5,null,["$5"],["jd"],0,0)
r(A,"kv",5,null,["$5"],["je"],0,0)
r(A,"ky",5,null,["$5"],["jh"],0,0)
r(A,"kr",5,null,["$5"],["ja"],0,0)
r(A,"kG",5,null,["$5"],["jp"],0,0)
r(A,"kI",5,null,["$5"],["jr"],0,0)
r(A,"kH",5,null,["$5"],["jq"],0,0)
r(A,"kR",5,null,["$5"],["jA"],0,0)
r(A,"kP",5,null,["$5"],["jy"],0,0)
r(A,"kT",5,null,["$5"],["jC"],0,0)
r(A,"kC",5,null,["$5"],["jl"],0,0)
r(A,"kx",5,null,["$5"],["jg"],0,0)
r(A,"kS",5,null,["$5"],["jB"],0,0)
r(A,"kz",5,null,["$5"],["ji"],0,0)
r(A,"l_",5,null,["$5"],["jJ"],0,0)
r(A,"kA",5,null,["$5"],["jj"],0,0)
r(A,"kJ",5,null,["$5"],["js"],0,0)
r(A,"kN",5,null,["$5"],["jw"],0,0)
r(A,"kO",5,null,["$5"],["jx"],0,0)
r(A,"kK",5,null,["$5"],["jt"],0,0)
r(A,"kF",5,null,["$5"],["jo"],0,0)
r(A,"kX",5,null,["$5"],["jG"],0,0)
r(A,"l1",5,null,["$5"],["jL"],0,0)
r(A,"l0",5,null,["$5"],["jK"],0,0)
r(A,"kQ",5,null,["$5"],["jz"],0,0)
r(A,"kY",5,null,["$5"],["jH"],0,0)
r(A,"kD",5,null,["$5"],["jm"],0,0)
r(A,"ko",5,null,["$5"],["j7"],0,0)
r(A,"kL",5,null,["$5"],["ju"],0,0)
r(A,"km",5,null,["$5"],["iA"],0,0)})();(function inheritance(){var t=hunkHelpers.inherit,s=hunkHelpers.inheritMany
t(A.p,null)
s(A.p,[A.dy,J.bU,A.bm,J.b1,A.w,A.cQ,A.e,A.bf,A.bu,A.a1,A.b6,A.au,A.a8,A.cR,A.cL,A.ad,A.aN,A.cE,A.ap,A.be,A.bd,A.aK,A.cf,A.cb,A.c5,A.ch,A.X,A.cd,A.ci,A.ce,A.aw,A.bP,A.bR,A.cX,A.cU,A.c1,A.bo,A.cV,A.cy,A.aq,A.bh,A.aQ,A.aS,A.a2,A.cP,A.at,A.d1,A.ar,A.b5,A.bg,A.bE,A.I,A.bJ,A.bK,A.C,A.cK,A.aP,A.cO,A.j,A.m,A.cT,A.d0,A.dv,A.a0,A.cZ,A.bI,A.ac,A.cJ])
s(J.bU,[J.bX,J.b9,J.aL,J.aI,J.ae])
s(J.aL,[J.af,J.k])
s(J.af,[J.cN,J.ab,J.ba])
t(J.bW,A.bm)
t(J.cA,J.k)
s(J.aI,[J.b8,J.bY])
s(A.w,[A.c0,A.bs,A.bZ,A.c8,A.c3,A.cc,A.bc,A.bG,A.T,A.bt,A.bp,A.bQ])
s(A.e,[A.b7,A.as,A.ca,A.cg])
s(A.b7,[A.F,A.a4,A.d,A.W])
s(A.F,[A.bq,A.L])
s(A.a1,[A.aT,A.aU])
t(A.aV,A.aT)
t(A.bv,A.aU)
t(A.aH,A.b6)
s(A.a8,[A.aG,A.bw])
s(A.aG,[A.an,A.J])
t(A.bi,A.bs)
s(A.ad,[A.bN,A.bO,A.c6,A.cl,A.co,A.cm,A.cn,A.d7,A.d9,A.cx,A.de,A.cq,A.cu,A.dk,A.dl,A.d8,A.dg])
s(A.c6,[A.c4,A.aE])
t(A.V,A.aN)
s(A.bO,[A.cB,A.cH,A.cY,A.cp,A.d6,A.da,A.db,A.cv,A.cw,A.d5,A.ct,A.df,A.dd,A.dc])
t(A.bb,A.V)
t(A.bx,A.cc)
t(A.av,A.bw)
t(A.c_,A.bc)
t(A.cC,A.bP)
t(A.cD,A.bR)
t(A.cW,A.cX)
s(A.T,[A.bk,A.bT])
s(A.cU,[A.o,A.l,A.bM,A.n,A.c9,A.a7,A.aR,A.c7,A.x,A.bL,A.cI,A.cs,A.b4,A.b2])
t(A.dh,A.bN)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{q:"int",ak:"double",K:"num",h:"String",H:"bool",bh:"Null",ag:"List",p:"Object",a5:"Map",aJ:"JSObject"},mangledNames:{},types:["q?(I,I,a2,a2,j)","q(q,q)","H(o)","q(o,o)","~(p?,p?)","I(at)","h(o)","H(I,a2)","~(q,n)","H(h)","h(h)","~(h,ak{detail:h?,intervals:q?})","H(q)","h()","h(h,h,h)","q(@,@)","@(@)"],arrayRti:Symbol("$ti"),rttc:{"3;midi,name,pc":(a,b,c)=>d=>d instanceof A.aV&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"4;addCount,alterationCount,naturalCount,totalCount":a=>b=>b instanceof A.bv&&A.ki(a,b.a)}}
A.io(v.typeUniverse,JSON.parse('{"ba":"af","cN":"af","ab":"af","bX":{"H":[],"a9":[]},"b9":{"a9":[]},"aL":{"aJ":[]},"af":{"aJ":[]},"k":{"ag":["1"],"aJ":[],"e":["1"]},"bW":{"bm":[]},"cA":{"k":["1"],"ag":["1"],"aJ":[],"e":["1"]},"b1":{"y":["1"]},"aI":{"ak":[],"K":[],"a3":["K"]},"b8":{"ak":[],"q":[],"K":[],"a3":["K"],"a9":[]},"bY":{"ak":[],"K":[],"a3":["K"],"a9":[]},"ae":{"h":[],"a3":["h"],"cM":[],"a9":[]},"c0":{"w":[]},"b7":{"e":["1"]},"F":{"e":["1"]},"bq":{"F":["1"],"e":["1"],"e.E":"1","F.E":"1"},"bf":{"y":["1"]},"L":{"F":["2"],"e":["2"],"e.E":"2","F.E":"2"},"as":{"e":["1"],"e.E":"1"},"bu":{"y":["1"]},"aV":{"aT":[],"a1":[]},"bv":{"aU":[],"a1":[]},"b6":{"a5":["1","2"]},"aH":{"b6":["1","2"],"a5":["1","2"]},"au":{"y":["1"]},"aG":{"a8":["1"],"bn":["1"],"e":["1"]},"an":{"aG":["1"],"a8":["1"],"bn":["1"],"e":["1"]},"J":{"aG":["1"],"a8":["1"],"bn":["1"],"e":["1"]},"bi":{"w":[]},"bZ":{"w":[]},"c8":{"w":[]},"ad":{"ao":[]},"bN":{"ao":[]},"bO":{"ao":[]},"c6":{"ao":[]},"c4":{"ao":[]},"aE":{"ao":[]},"c3":{"w":[]},"V":{"aN":["1","2"],"dB":["1","2"],"a5":["1","2"]},"a4":{"e":["1"],"e.E":"1"},"ap":{"y":["1"]},"d":{"e":["1"],"e.E":"1"},"be":{"y":["1"]},"W":{"e":["aq<1,2>"],"e.E":"aq<1,2>"},"bd":{"y":["aq<1,2>"]},"bb":{"V":["1","2"],"aN":["1","2"],"dB":["1","2"],"a5":["1","2"]},"aT":{"a1":[]},"aU":{"a1":[]},"aK":{"hR":[],"cM":[]},"cf":{"bl":[],"aO":[]},"ca":{"e":["bl"],"e.E":"bl"},"cb":{"y":["bl"]},"c5":{"aO":[]},"cg":{"e":["aO"],"e.E":"aO"},"ch":{"y":["aO"]},"cc":{"w":[]},"bx":{"w":[]},"av":{"a8":["1"],"bn":["1"],"e":["1"]},"aw":{"y":["1"]},"aN":{"a5":["1","2"]},"a8":{"bn":["1"],"e":["1"]},"bw":{"a8":["1"],"bn":["1"],"e":["1"]},"bc":{"w":[]},"c_":{"w":[]},"ak":{"K":[],"a3":["K"]},"q":{"K":[],"a3":["K"]},"ag":{"e":["1"]},"K":{"a3":["K"]},"bl":{"aO":[]},"h":{"a3":["h"],"cM":[]},"bG":{"w":[]},"bs":{"w":[]},"T":{"w":[]},"bk":{"w":[]},"bT":{"w":[]},"bt":{"w":[]},"bp":{"w":[]},"bQ":{"w":[]},"c1":{"w":[]},"bo":{"w":[]},"aQ":{"y":["q"]},"aS":{"i4":[]}}'))
A.im(v.typeUniverse,JSON.parse('{"b7":1,"bw":1,"bP":2,"bR":2}'))
var u=(function rtii(){var t=A.D
return{G:t("o"),u:t("n"),V:t("a3<@>"),I:t("aH<h,q>"),C:t("w"),Z:t("ao"),h:t("J<l>"),W:t("e<@>"),B:t("k<I>"),_:t("k<o>"),U:t("k<bI>"),d:t("k<a5<h,p?>>"),k:t("k<+midi,name,pc(q?,h?,q)>"),f:t("k<aR>"),s:t("k<h>"),r:t("k<at>"),b:t("k<@>"),t:t("k<q>"),T:t("b9"),m:t("aJ"),L:t("ba"),v:t("ag<H>"),j:t("ag<@>"),J:t("a5<@,@>"),Y:t("L<o,h>"),P:t("bh"),K:t("p"),M:t("lg"),F:t("+()"),e:t("bl"),N:t("h"),q:t("h(o)"),R:t("a9"),A:t("ab"),o:t("at"),y:t("H"),i:t("ak"),S:t("q"),O:t("ed<bh>?"),z:t("aJ?"),X:t("p?"),w:t("h?"),g:t("ce?"),c:t("H?"),x:t("ak?"),D:t("q?"),n:t("K?"),H:t("K")}})();(function constants(){var t=hunkHelpers.makeConstList
B.bC=J.bU.prototype
B.c=J.k.prototype
B.a=J.b8.prototype
B.F=J.aI.prototype
B.b=J.ae.prototype
B.bD=J.aL.prototype
B.b0=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.b1=new A.cC()
B.b2=new A.c1()
B.d=new A.cQ()
B.b3=new A.b2(0,"chosen")
B.b4=new A.b2(1,"nearTie")
B.b5=new A.b2(2,"unlikely")
B.v=new A.o(0,"flat9")
B.k=new A.o(1,"nine")
B.a9=new A.o(10,"add13")
B.b6=new A.o(11,"addFlat9")
B.I=new A.o(2,"sharp9")
B.R=new A.o(3,"addSharp9")
B.q=new A.o(4,"eleven")
B.o=new A.o(5,"sharp11")
B.w=new A.o(6,"flat13")
B.p=new A.o(7,"thirteen")
B.A=new A.o(8,"add9")
B.B=new A.o(9,"add11")
B.aL=new A.cs(0,"glyph")
B.ah=new A.bL(0,"symbolic")
B.b7=new A.bL(1,"textual")
B.b8=new A.bM(0,"triad")
B.r=new A.bM(1,"seventh")
B.bz=new A.b4(0,"symbolic")
B.bA=new A.b4(1,"textual")
B.bB=new A.b4(2,"academic")
B.t=new A.l(0,"major")
B.aM=new A.l(1,"majorFlat5")
B.a0=new A.l(10,"minor6")
B.n=new A.l(11,"dominant7")
B.aa=new A.l(12,"dominant7sus2")
B.a1=new A.l(13,"dominant7sus4")
B.C=new A.l(14,"dominant7Flat5")
B.y=new A.l(15,"dominant7Sharp5")
B.a2=new A.l(16,"major7")
B.ai=new A.l(17,"major7sus2")
B.ab=new A.l(18,"major7sus4")
B.V=new A.l(19,"major7Flat5")
B.D=new A.l(2,"minor")
B.W=new A.l(20,"major7Sharp5")
B.M=new A.l(21,"minor7")
B.N=new A.l(22,"minor7Sharp5")
B.S=new A.l(23,"minorMajor7")
B.X=new A.l(24,"halfDiminished7")
B.J=new A.l(25,"diminished7")
B.a3=new A.l(3,"minorSharp5")
B.a4=new A.l(4,"diminished")
B.a5=new A.l(5,"augmented")
B.aj=new A.l(6,"sus2")
B.ak=new A.l(7,"sus4")
B.al=new A.l(8,"sus2sus4")
B.E=new A.l(9,"major6")
B.l=new A.n(0,"root")
B.K=new A.n(1,"sus2")
B.L=new A.n(10,"sus4")
B.ac=new A.n(11,"eleven")
B.Y=new A.n(12,"sharp11")
B.ad=new A.n(13,"add11")
B.x=new A.n(14,"flat5")
B.e=new A.n(15,"perfect5")
B.u=new A.n(16,"sharp5")
B.O=new A.n(17,"sixth")
B.am=new A.n(18,"flat13")
B.ae=new A.n(19,"thirteenth")
B.T=new A.n(2,"flat9")
B.an=new A.n(20,"add13")
B.Z=new A.n(21,"dim7")
B.i=new A.n(22,"flat7")
B.z=new A.n(23,"major7")
B.ao=new A.n(3,"nine")
B.a_=new A.n(4,"sharp9")
B.af=new A.n(5,"add9")
B.aN=new A.n(6,"addSharp9")
B.m=new A.n(7,"minor3")
B.ap=new A.n(8,"splitMinor3")
B.f=new A.n(9,"major3")
B.bE=new A.cD(null)
B.ar=new A.aR(1,"naturalMinor")
B.aR=new A.aR(2,"harmonicMinor")
B.bU=t([B.ar,B.aR],u.f)
B.bV=t(["Too many notes. Enter no more than 128 note names or MIDI numbers."],u.s)
B.bW=t(["Type some notes, e.g. C E G or 60 64 67."],u.s)
B.aO=t(["B","E","A","D","G","C","F"],u.s)
B.aV=new A.x("Cb","C",11,0,"cFlat")
B.h=new A.c7(0,"major")
B.ci=new A.j(B.aV,B.h)
B.aC=new A.x("Ab","A",8,15,"aFlat")
B.j=new A.c7(1,"minor")
B.cG=new A.j(B.aC,B.j)
B.bQ=new A.C(-7,B.ci,B.cG)
B.aZ=new A.x("Gb","G",6,12,"gFlat")
B.ch=new A.j(B.aZ,B.h)
B.aG=new A.x("Eb","E",3,6,"eFlat")
B.cD=new A.j(B.aG,B.j)
B.bT=new A.C(-6,B.ch,B.cD)
B.b_=new A.x("Db","D",1,3,"dFlat")
B.cp=new A.j(B.b_,B.h)
B.aB=new A.x("Bb","B",10,18,"bFlat")
B.cg=new A.j(B.aB,B.j)
B.bP=new A.C(-5,B.cp,B.cg)
B.cF=new A.j(B.aC,B.h)
B.aA=new A.x("F","F",5,10,"f")
B.cl=new A.j(B.aA,B.j)
B.bS=new A.C(-4,B.cF,B.cl)
B.ct=new A.j(B.aG,B.h)
B.a8=new A.x("C","C",0,1,"c")
B.cI=new A.j(B.a8,B.j)
B.bJ=new A.C(-3,B.ct,B.cI)
B.cr=new A.j(B.aB,B.h)
B.aJ=new A.x("G","G",7,13,"g")
B.cA=new A.j(B.aJ,B.j)
B.bN=new A.C(-2,B.cr,B.cA)
B.cv=new A.j(B.aA,B.h)
B.aE=new A.x("D","D",2,4,"d")
B.cx=new A.j(B.aE,B.j)
B.bH=new A.C(-1,B.cv,B.cx)
B.aU=new A.j(B.a8,B.h)
B.aD=new A.x("A","A",9,16,"a")
B.co=new A.j(B.aD,B.j)
B.bG=new A.C(0,B.aU,B.co)
B.cE=new A.j(B.aJ,B.h)
B.aF=new A.x("E","E",4,7,"e")
B.cj=new A.j(B.aF,B.j)
B.bO=new A.C(1,B.cE,B.cj)
B.cz=new A.j(B.aE,B.h)
B.aI=new A.x("B","B",11,19,"b")
B.cs=new A.j(B.aI,B.j)
B.bK=new A.C(2,B.cz,B.cs)
B.cB=new A.j(B.aD,B.h)
B.aH=new A.x("F#","F",6,11,"fSharp")
B.cq=new A.j(B.aH,B.j)
B.bL=new A.C(3,B.cB,B.cq)
B.cH=new A.j(B.aF,B.h)
B.az=new A.x("C#","C",1,2,"cSharp")
B.cw=new A.j(B.az,B.j)
B.bR=new A.C(4,B.cH,B.cw)
B.cC=new A.j(B.aI,B.h)
B.aY=new A.x("G#","G",8,14,"gSharp")
B.cy=new A.j(B.aY,B.j)
B.bM=new A.C(5,B.cC,B.cy)
B.cu=new A.j(B.aH,B.h)
B.aW=new A.x("D#","D",3,5,"dSharp")
B.cn=new A.j(B.aW,B.j)
B.bF=new A.C(6,B.cu,B.cn)
B.ck=new A.j(B.az,B.h)
B.aX=new A.x("A#","A",10,17,"aSharp")
B.cm=new A.j(B.aX,B.j)
B.bI=new A.C(7,B.ck,B.cm)
B.bX=t([B.bQ,B.bT,B.bP,B.bS,B.bJ,B.bN,B.bH,B.bG,B.bO,B.bK,B.bL,B.bR,B.bM,B.bF,B.bI],A.D("k<C>"))
B.aP=t(["F","C","G","D","A","E","B"],u.s)
B.cL=new A.x("E#","E",5,8,"eSharp")
B.cK=new A.x("Fb","F",4,9,"fFlat")
B.cJ=new A.x("B#","B",0,20,"bSharp")
B.bY=t([B.aV,B.a8,B.az,B.b_,B.aE,B.aW,B.aG,B.aF,B.cL,B.cK,B.aA,B.aH,B.aZ,B.aJ,B.aY,B.aC,B.aD,B.aX,B.aB,B.aI,B.cJ],A.D("k<x>"))
B.aq=new A.aR(0,"major")
B.bZ=t([B.aq],u.f)
B.c_=t(["Input is too long. Enter no more than 512 characters."],u.s)
B.a6=t([],u.U)
B.G=t([],u.s)
B.c0=t([],u.r)
B.c2=t(["minor","major","min","maj"],u.s)
B.H=t(["C","D","E","F","G","A","B"],u.s)
B.c3=t(["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"],u.s)
B.b9=new A.m(B.t,145,128)
B.bk=new A.m(B.aM,81,0)
B.br=new A.m(B.D,137,128)
B.bs=new A.m(B.a3,265,0)
B.bt=new A.m(B.a4,73,0)
B.bu=new A.m(B.a5,273,0)
B.bv=new A.m(B.aj,133,0)
B.bw=new A.m(B.ak,161,0)
B.bx=new A.m(B.al,165,0)
B.by=new A.m(B.E,657,128)
B.ba=new A.m(B.a0,649,128)
B.bb=new A.m(B.n,1169,128)
B.bc=new A.m(B.aa,1157,128)
B.bd=new A.m(B.a1,1185,128)
B.be=new A.m(B.C,1105,0)
B.bf=new A.m(B.y,1297,0)
B.bg=new A.m(B.a2,2193,128)
B.bh=new A.m(B.ai,2181,128)
B.bi=new A.m(B.ab,2209,128)
B.bj=new A.m(B.V,2129,0)
B.bl=new A.m(B.W,2321,0)
B.bm=new A.m(B.M,1161,128)
B.bn=new A.m(B.N,1289,0)
B.bo=new A.m(B.S,2185,128)
B.bp=new A.m(B.X,1097,0)
B.bq=new A.m(B.J,585,0)
B.c4=t([B.b9,B.bk,B.br,B.bs,B.bt,B.bu,B.bv,B.bw,B.bx,B.by,B.ba,B.bb,B.bc,B.bd,B.be,B.bf,B.bg,B.bh,B.bi,B.bj,B.bl,B.bm,B.bn,B.bo,B.bp,B.bq],A.D("k<m>"))
B.c6={C:0,D:1,E:2,F:3,G:4,A:5,B:6}
B.ag=new A.aH(B.c6,[0,2,4,5,7,9,11],u.I)
B.c8={major:0,dominant7:1,minor:2,minor7:3,major7:4,"dominant7|nine":5,diminished:6,major6:7,halfDiminished7:8,"dominant7|flat9":9,minor6:10,"dominant7|nine,eleven,thirteen":11,diminished7:12,dominant7Sharp5:13,"minor7|nine":14,augmented:15,dominant7sus4:16,"major7|nine":17,sus4:18,"major6|add9":19,"dominant7|sharp9":20,"dominant7sus4|nine":21,dominant7Flat5:22,"minor7|nine,eleven":23,sus2:24,minorMajor7:25,"dominant7|nine,sharp11":26,major7sus4:27,"dominant7Sharp5|flat9":28,"dominant7Sharp5|sharp9":29,"dominant7|flat9,add11,add13":30,"dominant7Sharp5|nine":31,"dominant7|sharp11":32,minorSharp5:33,"dominant7Flat5|flat9":34,"major|add9":35,"dominant7sus4|nine,eleven,thirteen":36,"dominant7|nine,eleven":37,"major7|nine,sharp11":38,"dominant7|nine,sharp11,thirteen":39,"dominant7Flat5|nine":40,"major7sus4|nine":41,"major7|nine,eleven,thirteen":42,"dominant7|sharp9,sharp11,flat13":43,"minor6|add9":44,minor7Sharp5:45,"dominant7Flat5|flat9,flat13":46,major7Sharp5:47,"dominant7Flat5|nine,eleven,thirteen":48,"dominant7sus4|flat9":49,"dominant7|flat9,nine,eleven,thirteen":50,"dominant7|flat13":51,"dominant7Flat5|nine,thirteen":52,"dominant7Flat5|sharp9":53,"dominant7|flat9,sharp11":54,"minor|add9":55,"major7|sharp11":56,"minor7|nine,eleven,thirteen":57,"dominant7|flat9,sharp11,add13":58,"major|add11":59,"dominant7sus4|sharp9":60,"minor|addFlat9":61,"major7sus4|add13":62,"dominant7|sharp9,flat13":63,"major7|nine,sharp11,thirteen":64,"dominant7|sharp9,add11,add13":65,"dominant7Sharp5|sharp9,sharp11":66,"major7Sharp5|nine":67,"dominant7|nine,eleven,sharp11,thirteen":68,"major7sus4|nine,eleven,thirteen":69,"minor7|add11":70,major7Flat5:71,"major|sharp11":72,"dominant7|flat9,flat13,add11":73,"minor|addSharp9":74,"dominant7|flat9,sharp9,sharp11,flat13":75,"dominant7Flat5|flat9,add11,add13":76,"dominant7|sharp9,sharp11,add13":77,"dominant7|flat9,flat13":78,"dominant7|nine,eleven,flat13":79,"major|addFlat9":80,"major7|sharp9":81,"dominant7Flat5|flat9,add13":82,"minor|add11":83,"dominant7Sharp5|sharp11":84,"major7sus4|flat9":85,"minor7|flat9":86,"dominant7Sharp5|nine,eleven,thirteen":87,"dominant7|sharp9,sharp11":88,"minorMajor7|nine":89,"minorMajor7|nine,eleven,thirteen":90,"minorMajor7|nine,sharp11":91,"dominant7Sharp5|flat9,add11,add13":92,"dominant7|add11":93,"halfDiminished7|nine":94,"major6|sharp11,add9":95,"major|sharp9":96,"dominant7Sharp5|nine,sharp11":97,"dominant7sus4|flat9,add11,add13":98,"halfDiminished7|nine,eleven":99,"major|add9,add11":100,"minor|addFlat9,add9":101,"minor|sharp11":102,"sus4|addFlat9":103,"minor6|flat9":104,"dominant7Sharp5|add11":105,"dominant7Sharp5|nine,thirteen":106,"dominant7|sharp11,flat13":107,"major7Flat5|nine":108,"sus4|add9":109,"augmented|add9":110,"diminished|add11":111,"diminished|addFlat9":112,"dominant7Sharp5|flat9,sharp11":113,"dominant7|nine,flat13":114,"halfDiminished7|flat9":115,"major7Sharp5|sharp9":116,"major7|add11":117,"major7|sharp9,sharp11":118}
B.c5=new A.aH(B.c8,[377568,235374,126463,116677,40596,29941,24716,23897,14746,11213,10366,8947,8083,7470,5800,4760,4179,3440,2958,2943,2710,2530,2426,2193,1423,1365,1285,1127,1098,900,896,750,563,531,509,498,459,388,346,314,292,277,274,263,236,207,135,135,107,103,102,85,65,57,56,55,53,50,43,43,39,35,33,30,29,28,27,27,26,25,25,24,21,20,18,17,16,16,15,15,15,13,12,12,10,9,9,8,8,8,8,8,6,6,5,5,5,4,4,4,4,4,4,4,3,2,2,2,2,2,1,1,1,1,1,1,1,1,1],u.I)
B.P=new A.cI(0,"international")
B.c1=t([],u.t)
B.aK=new A.c9(0,"exact")
B.aQ=new A.aP(B.c1,B.aK)
B.Q=new A.a7(0,"one")
B.as=new A.a7(1,"two")
B.at=new A.a7(2,"three")
B.au=new A.a7(3,"four")
B.av=new A.a7(4,"five")
B.aw=new A.a7(5,"six")
B.ax=new A.a7(6,"seven")
B.ca=new A.J([B.o],A.D("J<o>"))
B.c9={A:0,B:1,C:2,D:3,E:4,F:5,G:6}
B.cb=new A.an(B.c9,7,A.D("an<h>"))
B.a7=new A.J([B.t,B.a2],u.h)
B.cc=new A.J([B.t,B.n,B.y],u.h)
B.cd=new A.J([B.a5,B.W],u.h)
B.ce=new A.J([B.D,B.S],u.h)
B.U=new A.J([B.D,B.M],u.h)
B.c7={}
B.aS=new A.an(B.c7,0,A.D("an<o>"))
B.cf=new A.J([B.a4,B.J],u.h)
B.ay=new A.J([B.a4,B.X],u.h)
B.aT=new A.J([B.t,B.n],u.h)
B.cM=A.lc("p")
B.cN=new A.c9(1,"synthesized")})();(function staticFields(){$.N=A.i([],A.D("k<p>"))
$.ei=null
$.e1=null
$.e0=null
$.d_=A.i([],A.D("k<ag<p>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"lf","fi",()=>A.fc("_$dart_dartClosure"))
t($,"le","dX",()=>A.fc("_$dart_dartClosure_dartJSInterop"))
t($,"lt","fu",()=>A.i([new J.bW()],A.D("k<bm>")))
t($,"li","fk",()=>A.aa(A.cS({
toString:function(){return"$receiver$"}})))
t($,"lj","fl",()=>A.aa(A.cS({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"lk","fm",()=>A.aa(A.cS(null)))
t($,"ll","fn",()=>A.aa(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"lo","fq",()=>A.aa(A.cS(void 0)))
t($,"lp","fr",()=>A.aa(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"ln","fp",()=>A.aa(A.er(null)))
t($,"lm","fo",()=>A.aa(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"lr","ft",()=>A.aa(A.er(void 0)))
t($,"lq","fs",()=>A.aa(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"ls","b_",()=>A.dV(B.cM))
t($,"ld","fh",()=>A.hI(u.S,A.D("ag<I>")))
t($,"lv","dY",()=>A.i([A.v(A.u(B.t),3080,!1),A.v(A.u(B.aM),3208,!1),A.v(A.u(B.D),3088,!1),A.v(A.u(B.a3),3216,!1),A.v(A.u(B.a4),144,!1),A.v(A.u(B.a5),136,!1),A.v(A.u(B.aj),3096,!1),A.v(A.u(B.ak),3096,!1),A.v(A.u(B.al),0,!0),A.v(A.u(B.E),3080,!1),A.v(A.u(B.a0),3088,!1),A.v(A.u(B.n),2056,!1),A.v(A.u(B.aa),2104,!1),A.v(A.u(B.a1),2072,!1),A.v(A.u(B.C),2184,!1),A.v(A.u(B.y),2184,!1),A.v(A.u(B.a2),1032,!1),A.v(A.u(B.ai),1080,!1),A.v(A.u(B.ab),1048,!1),A.v(A.u(B.V),1160,!1),A.v(A.u(B.W),1160,!1),A.v(A.u(B.M),2064,!1),A.v(A.u(B.N),2192,!1),A.v(A.u(B.S),1040,!1),A.v(A.u(B.X),2192,!1),A.v(A.u(B.J),3216,!1)],A.D("k<b5>")))
t($,"lw","fw",()=>A.i([A.f("prefer complete dominant flat-nine over colored diminished7",A.ks()),A.f("prefer flat-nine-bass dominant over remote reinterpretation",A.kM()),A.f("prefer complete altered dominant inversion over altered major7",A.kq()),A.f("prefer complete dominant sharp-nine over split-third sixth",A.kt()),A.f("prefer complete altered sharp-five dominant over remote spellings",A.kr()),A.f("prefer conventional inversion in split-nine tritone dominant ambiguity",A.kE()),A.f("prefer altered dominant7 over dim7 slash",A.kp()),A.f("prefer conventional altered seventh over add11 slash",A.kC()),A.f("prefer complete minor sharp11 over altered maj7sus4",A.kx()),A.f("prefer close root-position dominant7 over non-dominant slash",A.kH()),A.f("prefer ninth-bass seventh chord over altered slash",A.kR()),A.f("prefer minor7 eleventh-bass slash over minor7 sharp-five slash",A.kP()),A.f("prefer root-position altered-fifth dominant over slash",A.kT()),A.f("prefer root-position add-chord over sus slash",A.kS()),A.f("prefer complete triad over structurally deficient reading",A.kA()),A.f("prefer root-position minor-eleventh shell over sus slash",A.kW()),A.f("prefer complete major six-nine over inverted minor-seven sharp-five",A.kw()),A.f("prefer simple triad add-tone over seventh-family unusual quality",A.l_())],A.D("k<bg>")))
t($,"lx","fx",()=>A.i([A.f("prefer root-position 6th over inverted 7th",A.kn()),A.f("prefer complete triad over incomplete inverted 6th",A.kB()),A.f("prefer upper-structure dominant7 slash",A.l2()),A.f("prefer root-position dominant sus over slash",A.kU()),A.f("prefer root-position extended dominant over altered-fifth slash",A.kV()),A.f("prefer complete sharp-nine thirteenth dominant over colored sixth",A.ky()),A.f("prefer sharp-five sharp-eleven dominant spelling over flat-five flat-thirteen",A.kZ()),A.f("prefer complete major inversion over minor sharp-five",A.ku()),A.f("prefer complete major inversion over seventh-family color-bass slash",A.kv()),A.f("prefer root-position diminished7",A.kG()),A.f("prefer dominant7 over dim7 slash",A.kI()),A.f("prefer dominant7 shell slash over non-dominant seventh-family slash",A.kJ()),A.f("prefer voicing that names every tone",A.kN()),A.f("prefer harmonic-minor tonic over split-third inversion",A.kO()),A.f("prefer fewer altered/tension colors",A.kK()),A.f("prefer diatonic chords",A.kF()),A.f("prefer root-position relative minor7 over major6 slash",A.kX()),A.f("prefer tonic chord",A.l1()),A.f("prefer I chord when bass is tonic",A.l0()),A.f("prefer complete triad add-tone over seventh-family add-tone",A.kz()),A.f("prefer natural extensions over adds, then fewer total",A.kQ()),A.f("prefer root position",A.kY()),A.f("prefer common naming preference",A.k0()),A.f("prefer more conventional inversion",A.kD()),A.f("prefer 7th chords over triads",A.ko()),A.f("prefer fewer extensions",A.kL()),A.f("avoid suspended chords",A.km())],A.D("k<bg>")))
t($,"lu","fv",()=>{var s,r,q=A.aM(A.D("l"),A.D("m"))
for(s=0;s<26;++s){r=B.c4[s]
q.u(0,r.a,r)}return q})
t($,"lh","fj",()=>{var s,r,q,p=A.aM(A.D("l"),A.D("b5"))
for(s=$.dY(),r=0;r<26;++r){q=s[r]
p.u(0,q.a,q)}return p})})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}}()
hunkHelpers.setOrUpdateInterceptorsByTag({})
hunkHelpers.setOrUpdateLeafTags({})})()
Function.prototype.$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$5=function(a,b,c,d,e){return this(a,b,c,d,e)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.kh
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()