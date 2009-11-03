#include "mouse.h"

#define ISA_CACHE "::LINEALIZED_ISA_CACHE::"

#ifdef no_mro_get_linear_isa
AV*
mouse_mro_get_linear_isa(pTHX_ HV* const stash){
    GV* const cachegv = *(GV**)hv_fetchs(stash, ISA_CACHE, TRUE);
    AV* isa;
    SV* gen;
    CV* get_linear_isa;

    if(!isGV(cachegv))
        gv_init(cachegv, stash, ISA_CACHE, sizeof(ISA_CACHE)-1, TRUE);

    isa = GvAVn(cachegv);
    gen = GvSVn(cachegv);


    if(SvIOK(gen) && SvIVX(gen) == (IV)mro_get_pkg_gen(stash)){
        return isa; /* returns the cache if available */
    }
    else{
        SvREFCNT_dec(isa);
        GvAV(cachegv) = isa = newAV();
    }

    get_linear_isa = get_cv("Mouse::Util::get_linear_isa", TRUE);

    {
        SV* avref;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        mXPUSHp(HvNAME_get(stash), HvNAMELEN_get(stash));
        PUTBACK;

        call_sv((SV*)get_linear_isa, G_SCALAR);

        SPAGAIN;
        avref = POPs;
        PUTBACK;

        if(IsArrayRef(avref)){
            AV* const av  = (AV*)SvRV(avref);
            I32 const len = AvFILLp(av) + 1;
            I32 i;

            for(i = 0; i < len; i++){
                HV* const stash = gv_stashsv(AvARRAY(av)[i], FALSE);
                if(stash)
                    av_push(isa, newSVpv(HvNAME(stash), 0));
            }
            SvREADONLY_on(isa);
        }
        else{
            Perl_croak(aTHX_ "Mouse:Util::get_linear_isa() didn't return an ARRAY reference");
        }

        FREETMPS;
        LEAVE;
    }

    sv_setiv(gen, (IV)mro_get_pkg_gen(stash));
    return isa;
}
#endif /* !no_mor_get_linear_isa */

#ifdef DEBUGGING
SV**
mouse_av_at_safe(pTHX_ AV* const av, I32 const ix){
    assert(av);
    assert(SvTYPE(av) == SVt_PVAV);
    assert(AvMAX(av) >= ix);
    return &AvARRAY(av)[ix];
}
#endif

void
mouse_throw_error(SV* const metaobject, SV* const data /* not used */, const char* const fmt, ...){
    dTHX;
    va_list args;
    SV* message;

    PERL_UNUSED_ARG(data); /* for moose-compat */

    assert(metaobject);
    assert(fmt);

    va_start(args, fmt);
    message = vnewSVpvf(fmt, &args);
    va_end(args);

    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 4);

        PUSHs(metaobject);
        mPUSHs(message);

        mPUSHs(newSVpvs("depth"));
        mPUSHi(-1);

        PUTBACK;

        call_method("throw_error", G_VOID);
        croak("throw_error() did not throw the error (%"SVf")", message);
    }
}

bool
mouse_is_class_loaded(pTHX_ SV * const klass){
    HV *stash;
    GV** gvp;
    HE* he;

    if (!(SvPOKp(klass) && SvCUR(klass))) { /* XXX: SvPOK does not work with magical scalars */
        return FALSE;
    }

    stash = gv_stashsv(klass, FALSE);
    if (!stash) {
        return FALSE;
    }

    if (( gvp = (GV**)hv_fetchs(stash, "VERSION", FALSE) )) {
        if(isGV(*gvp) && GvSV(*gvp) && SvOK(GvSV(*gvp))){
            return TRUE;
        }
    }

    if (( gvp = (GV**)hv_fetchs(stash, "ISA", FALSE) )) {
        if(isGV(*gvp) && GvAV(*gvp) && av_len(GvAV(*gvp)) != -1){
            return TRUE;
        }
    }

    hv_iterinit(stash);
    while(( he = hv_iternext(stash) )){
        GV* const gv = (GV*)HeVAL(he);

        if(isGV(gv)){
            if(GvCVu(gv)){
                return TRUE;
            }
        }
        else if(SvOK(gv)){
            return TRUE;
        }
    }
    return FALSE;
}


SV *
mouse_call0 (pTHX_ SV *const self, SV *const method)
{
    dSP;
    SV *ret;

    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;

    call_sv(method, G_SCALAR | G_METHOD);

    SPAGAIN;
    ret = POPs;
    PUTBACK;

    return ret;
}

SV *
mouse_call1 (pTHX_ SV *const self, SV *const method, SV* const arg1)
{
    dSP;
    SV *ret;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(self);
    PUSHs(arg1);
    PUTBACK;

    call_sv(method, G_SCALAR | G_METHOD);

    SPAGAIN;
    ret = POPs;
    PUTBACK;

    return ret;
}

MAGIC*
mouse_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl, I32 const flags){
    MAGIC* mg;

    assert(sv != NULL);
    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            return mg;
        }
    }

    if(flags & MOUSEf_DIE_ON_FAIL){
        croak("mouse_mg_find: no MAGIC found for %"SVf, sv_2mortal(newRV_inc(sv)));
    }
    return NULL;
}

MODULE = Mouse::Util  PACKAGE = Mouse::Util

PROTOTYPES:   DISABLE
VERSIONCHECK: DISABLE

bool
is_class_loaded(SV* sv)

void
get_code_info(CV* code)
PREINIT:
    GV* gv;
    HV* stash;
PPCODE:
    if((gv = CvGV(code)) && isGV(gv) && (stash = GvSTASH(gv))){
        EXTEND(SP, 2);
        mPUSHs(newSVpvn_share(HvNAME_get(stash), HvNAMELEN_get(stash), 0U));
        mPUSHs(newSVpvn_share(GvNAME_get(gv), GvNAMELEN_get(gv), 0U));
    }

SV*
get_code_package(CV* code)
PREINIT:
    HV* stash;
CODE:
    if(CvGV(code) && isGV(CvGV(code)) && (stash = GvSTASH(CvGV(code)))){
        RETVAL = newSVpvn_share(HvNAME_get(stash), HvNAMELEN_get(stash), 0U);
    }
    else{
        RETVAL = &PL_sv_no;
    }
OUTPUT:
    RETVAL

CV*
get_code_ref(SV* package, SV* name)
CODE:
{
    HV* stash;
    HE* he;

    if(!SvOK(package)){
        croak("You must define a package name");
    }
    if(!SvOK(name)){
        croak("You must define a subroutine name");
    }

    stash = gv_stashsv(package, FALSE);
    if(!stash){
        XSRETURN_UNDEF;
    }
    he = hv_fetch_ent(stash, name, FALSE, 0U);
    if(he){
        GV* const gv = (GV*)hv_iterval(stash, he);
        if(!isGV(gv)){ /* special constant or stub */
            STRLEN len;
            const char* const pv = SvPV_const(name, len);
            gv_init(gv, stash, pv, len, GV_ADDMULTI);
        }
        RETVAL = GvCVu(gv);
    }
    else{
        RETVAL = NULL;
    }

    if(!RETVAL){
        XSRETURN_UNDEF;
    }
}
OUTPUT:
    RETVAL

void
generate_isa_predicate_for(SV* klass, SV* predicate_name = NULL)
PPCODE:
{
    const char* name_pv = NULL;
    CV* xsub;

    SvGETMAGIC(klass);

    if(!SvOK(klass)){
        croak("You must define a class name");
    }

    if(predicate_name){
        SvGETMAGIC(predicate_name);
        if(!SvOK(predicate_name)){
            croak("You must define a predicate_name");
        }
        name_pv = SvPV_nolen_const(predicate_name);
    }

    xsub = mouse_generate_isa_predicate_for(aTHX_ klass, name_pv);

    if(predicate_name == NULL){ /* anonymous predicate */
        XPUSHs( newRV_noinc((SV*)xsub) );
    }
}