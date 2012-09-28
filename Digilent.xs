#define _WIN32_WINNT 0x0502 /* XPSP2 or later */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <windows.h>

#define MY_CXT_KEY "Device::Digilent::_guts" XS_VERSION


typedef int16_t TRID;
typedef int32_t ERC;
typedef int32_t TRT;
typedef int32_t STS;
typedef int32_t DVCT;

/* Digilent defines this as a full HANDLE, but in practice it appears to always
 * be a small integer. Declaring it as such avoids some annoying casts, albeit
 * with the risk that Digilent will start using it as a real HANDLE at some
 * point in the future.
 */
typedef intptr_t DPCHANDLE;

typedef struct TRS {
    TRT  trt;
    TRID trid;
    STS  sts;
    ERC  erc;
} TRS;


#define LOAD_DPC_FN(fn) do { \
    if (!(MY_CXT.fn = (void *) GetProcAddress(dpcutil, #fn))) \
        croak("missing function: " #fn); \
} while(0)

#define DPC_FN(ret, fn, ...) ret (*fn)(__VA_ARGS__)

/* NB: I've inferred a "const" specifier on rgbAddr* arguments, and on rgbData*
 * for write operations.
 *
 * This isn't actually guaranteed by DPCUTIL, but it's unlikely that the
 * library would violate it.
 */

typedef struct {
    HMODULE dpcutil;

    DPC_FN(bool, DpcInit, ERC *);
    DPC_FN(void, DpcTerm);

/*
    DPC_FN(bool, DpcStartNotify, HWND, WORD, ERC *);
    DPC_FN(bool, DpcEndNotify, HWND, ERC *);
    DPC_FN(bool, DpcPendingTransactions, DPCHANDLE, int *, ERC *);
    DPC_FN(bool, DpcQueryConfigStatus, DPCHANDLE, TRID, TRS *, ERC *);
    DPC_FN(bool, DpcAbortConfigTransaction, DPCHANDLE, TRID, ERC *);
    DPC_FN(bool, DpcClearConfigStatus, DPCHANDLE, TRID, ERC *);
    DPC_FN(bool, DpcWaitForTransaction, DPCHANDLE, TRID, ERC *);
    DPC_FN(ERC, DpcGetFirstError, DPCHANDLE);
*/

    DPC_FN(bool, DpcGetDpcVersion, char *, ERC *);

/*
    DPC_FN(bool, DpcOpenJtag, DPCHANDLE *, const char *, ERC *, TRID *);
    DPC_FN(bool, DpcCloseJtag, DPCHANDLE, ERC *);
    DPC_FN(bool, DpcEnableJtag, DPCHANDLE, ERC *, TRID *);
    DPC_FN(bool, DpcDisableJtag, DPCHANDLE, ERC *, TRID *);
    DPC_FN(bool, DpcSetTmsTdiTck, DPCHANDLE, bool, bool, bool, TRID *);
    DPC_FN(bool, DpcPutTdiBits, DPCHANDLE, int, const BYTE *, bool, bool, BYTE *, ERC *, TRID *);
    DPC_FN(bool, DpcPutTmsTdiBits, DPCHANDLE, int, const BYTE *, bool, BYTE *, ERC *, TRID *);
    DPC_FN(bool, DpcGetTdoBits, DPCHANDLE, int, bool, bool, BYTE *, ERC *, TRID *);
*/

    DPC_FN(bool, DpcOpenData, DPCHANDLE *, const char *, ERC *, TRID *);
    DPC_FN(bool, DpcCloseData, DPCHANDLE, ERC *);
    DPC_FN(bool, DpcPutReg, DPCHANDLE, BYTE, BYTE, ERC *, TRID *);
    DPC_FN(bool, DpcGetReg, DPCHANDLE, BYTE, BYTE *, ERC *, TRID *);
    DPC_FN(bool, DpcPutRegSet, DPCHANDLE, const BYTE *, const BYTE *, int, ERC *, TRID *);
    DPC_FN(bool, DpcGetRegSet, DPCHANDLE, const BYTE *, BYTE *, int, ERC *, TRID *);
    DPC_FN(bool, DpcPutRegRepeat, DPCHANDLE, BYTE, const BYTE *, int, ERC *, TRID *);
    DPC_FN(bool, DpcGetRegRepeat, DPCHANDLE, BYTE, BYTE *, int, ERC *, TRID *);

    DPC_FN(void, DvmgStartConfigureDevices, HWND, ERC *);
    DPC_FN(int,  DvmgGetDevCount, ERC *);
    DPC_FN(bool, DvmgGetDevName, int, char *, ERC *);
    DPC_FN(bool, DvmgGetDevType, int, DVCT *, ERC *);
    DPC_FN(int,  DvmgGetDefaultDev, ERC *);
    DPC_FN(int,  DvmgGetHDVC, char *, ERC *);

} my_cxt_t;

void croak_dpc(const char *func, ERC err) {
    const char *msg = NULL;
    switch (err) {
        case 0:    msg = "no error"; break;
        case 3001: msg = "connection rejected"; break;
        case 3002: msg = "connection type"; break; // ?
        case 3003: msg = "connection no mode"; break; // ?
        case 3004: msg = "invalid parameter"; break;
        case 3005: msg = "invalid command"; break;
        case 3006: msg = "unknown error"; break;
        case 3007: msg = "JTAG conflict"; break;
        case 3008: msg = "not implemented"; break;
        case 3009: msg = "out of memory"; break;
        case 3010: msg = "timeout"; break;
        case 3011: msg = "conflict"; break;
        case 3012: msg = "bad packet"; break;
        case 3013: msg = "invalid option"; break;
        case 3014: msg = "already connected";
        case 3101: msg = "connected"; break; // ?
        case 3102: msg = "device not initialized"; break;
        case 3103: msg = "can't connect to module"; break;
        case 3104: msg = "already connected to module"; break;
        case 3105: msg = "send error"; break;
        case 3106: msg = "receive error"; break;
        case 3107: msg = "abort failed"; break;
        case 3108: msg = "timeout"; break;
        case 3109: msg = "out of order"; break;
        case 3110: msg = "too much data"; break;
        case 3111: msg = "missing data"; break;
        case 3201: msg = "transaction not found"; break;
        case 3202: msg = "transaction not complete"; break;
        case 3203: msg = "transaction not connected"; break;
        case 3204: msg = "wrong mode"; break;
        case 3205: msg = "wrong version"; break;
        case 3301: msg = "device table doesn't exist"; break;
        case 3302: msg = "device table corrupted"; break;
        case 3303: msg = "device not found in device table"; break;
        case 3304: msg = "initialization failed"; break;
        case 3305: msg = "thoroughly unknown error"; break;
        case 3306: msg = "dialog already open"; break;
        case 3307: msg = "registry error"; break;
        case 3308: msg = "registry full"; break;
        case 3309: msg = "not found"; break;
        case 3310: msg = "incompatible firmware"; break;
        case 3311: msg = "invalid handle"; break;
        default: croak("%s: mysterious error %d", func, err);
    }
    croak("%s: %s", func, msg);
}

START_MY_CXT

MODULE = Device::Digilent PACKAGE = Device::Digilent

BOOT:
{
    MY_CXT_INIT;
    SetDllDirectory(""); /* Removes cwd from DLL search path */
    HMODULE dpcutil = MY_CXT.dpcutil = LoadLibrary("dpcutil");
    if (!dpcutil)
        croak("Couldn't load dpcutil");

    LOAD_DPC_FN(DpcInit);
    LOAD_DPC_FN(DpcTerm);
    LOAD_DPC_FN(DpcGetDpcVersion);
    LOAD_DPC_FN(DvmgGetDevCount);
    LOAD_DPC_FN(DvmgStartConfigureDevices);
    LOAD_DPC_FN(DvmgGetHDVC);
    LOAD_DPC_FN(DvmgGetDefaultDev);
    LOAD_DPC_FN(DvmgGetDevName);
    LOAD_DPC_FN(DvmgGetDevType);
    LOAD_DPC_FN(DpcOpenData);
    LOAD_DPC_FN(DpcCloseData);
    LOAD_DPC_FN(DpcGetReg);
    LOAD_DPC_FN(DpcGetRegSet);
    LOAD_DPC_FN(DpcGetRegRepeat);
    LOAD_DPC_FN(DpcPutReg);
    LOAD_DPC_FN(DpcPutRegSet);
    LOAD_DPC_FN(DpcPutRegRepeat);
}


PROTOTYPES: ENABLE


MODULE = Device::Digilent PACKAGE = Device::Digilent

void
Init()
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        if (!MY_CXT.DpcInit(&err))
            croak_dpc("DpcInit", err);

void
Terminate()
    PREINIT:
        dMY_CXT;
    CODE:
        MY_CXT.DpcTerm();

SV *
Version()
    PREINIT:
        dMY_CXT;
    CODE:
        char buf[128];
        ERC err;
        if (!MY_CXT.DpcGetDpcVersion(buf, &err))
            croak_dpc("DpcGetDpcVersion", err);
        RETVAL = newSVpv(buf, 0);
    OUTPUT:
        RETVAL



MODULE = Device::Digilent PACKAGE = Device::Digilent::Config

int
Count()
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        int n = MY_CXT.DvmgGetDevCount(&err);
        if (err)
            croak_dpc("DvmgGetDevCount", err);
        RETVAL = n;
    OUTPUT:
        RETVAL

void
RunPanel()
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        MY_CXT.DvmgStartConfigureDevices(NULL, &err);
        if (err)
            croak_dpc("DvmgStartConfigureDevices", err);

int
Default()
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        int n = MY_CXT.DvmgGetDefaultDev(&err);
        if (err)
            croak_dpc("DvmgGetDefaultDev", err);
        RETVAL = n;
    OUTPUT:
        RETVAL

SV *
GetName(int idx)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        char buf[128];
        if (!MY_CXT.DvmgGetDevName(idx, buf, &err))
            croak_dpc("DvmgGetDevName", err);
        RETVAL = newSVpv(buf, 0);
    OUTPUT:
        RETVAL

int
GetType(int idx)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DVCT type;
        if (!MY_CXT.DvmgGetDevType(idx, &type, &err))
            croak_dpc("DvmgGetDevType", err);
        RETVAL = type;
    OUTPUT:
        RETVAL


MODULE = Device::Digilent PACKAGE = Device::Digilent::Data

#define DDD_HANDLE SvIV(SvRV(self)); \
        if (h == (DPCHANDLE) 0) croak("Connection not open");

#define SANE_REGISTER(reg) do { \
    if (reg < 0 || reg > 255) croak("Invalid register %d", reg); \
} while(0)

SV *
new(SV *class, char *name)
    PREINIT:
        dMY_CXT;
    CODE:
        DPCHANDLE h;
        ERC err;
        if (!SvPOK(class)) croak("Must be initialized as a class");
        if (MY_CXT.DpcOpenData(&h, name, &err, NULL))
            RETVAL = sv_setref_iv(newSV(0), SvPVX(class), h);
        else
            croak_dpc("DpcOpenData", err);
    OUTPUT:
        RETVAL

void
DESTROY(SV *self)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        if (!MY_CXT.DpcCloseData(h, &err))
            croak_dpc("DpcCloseData", err);

void
Close(SV *self)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        if (MY_CXT.DpcCloseData(h, &err))
            SvIV_set(SvRV(self), 0); // flag as closed
        else
            croak_dpc("DpcCloseData", err);

int
GetByte(SV *self, int reg)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        BYTE data;
        DPCHANDLE h = DDD_HANDLE;
        SANE_REGISTER(reg);
        if (!MY_CXT.DpcGetReg(h, reg, &data, &err, NULL))
            croak_dpc("DpcGetReg", err);
        RETVAL = data;
    OUTPUT:
        RETVAL

void
GetMulti(SV *self, SV *bufsv, ...)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        int i, ok, regs = items - 2;
        if (!SvOK(bufsv)) sv_setpvs(bufsv, "");
        SvPOK_only(bufsv);
        char *datbuf = SvGROW(bufsv, (STRLEN)(regs + 1));
        BYTE *regbuf;
        Newx(regbuf, regs, BYTE);
        for (i = 0; i < regs; i++) {
            IV reg = SvIV(ST(i + 2));
            if (reg < 0 || reg > 255) {
                Safefree(regbuf);
                croak("Invalid register %d", reg);
            }
            regbuf[i] = reg;
        }
        ok = MY_CXT.DpcGetRegSet(h, regbuf, datbuf, regs, &err, NULL);
        Safefree(regbuf);
        if (ok) {
            SvCUR_set(bufsv, regs);
            *SvEND(bufsv) = 0;
            SvSETMAGIC(bufsv);
        } else {
            SvCUR_set(bufsv, 0);
            SvSETMAGIC(bufsv);
            croak_dpc("DpcGetRegSet", err);
        }

void
GetRepeat(SV *self, int reg, SV *bufsv, int count)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        SANE_REGISTER(reg);
        if (count <= 0) croak("Negative length");
        if (!SvOK(bufsv)) sv_setpvs(bufsv, "");
        SvPOK_only(bufsv);
        char *buf = SvGROW(bufsv, (STRLEN)(count + 1));
        if (MY_CXT.DpcGetRegRepeat(h, reg, buf, count, &err, NULL)) {
            SvCUR_set(bufsv, count);
            *SvEND(bufsv) = 0;
            SvSETMAGIC(bufsv);
        } else {
            SvCUR_set(bufsv, 0);
            SvSETMAGIC(bufsv);
            croak_dpc("DpcGetRegRepeat", err);
        }

void
PutByte(SV *self, int reg, int data)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        SANE_REGISTER(reg);
        if (!MY_CXT.DpcPutReg(h, reg, data, &err, NULL))
            croak_dpc("DpcPutReg", err);

void
PutMulti(SV *self, SV *bufsv, ...)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        int i, ok, regs = items - 2;
        if (!SvPOK(bufsv)) croak("Buffer must be a string");
        STRLEN blen;
        const BYTE *datbuf = SvPV_const(bufsv, blen);
        if (regs > blen) croak("Buffer must be at least as long as register list");
        BYTE *regbuf;
        Newx(regbuf, regs, BYTE);
        for (i = 0; i < regs; i++) {
            IV reg = SvIV(ST(i + 2));
            if (reg < 0 || reg > 255) {
                Safefree(regbuf);
                croak("Invalid register %d", reg);
            }
            regbuf[i] = reg;
        }
        ok = MY_CXT.DpcPutRegSet(h, regbuf, datbuf, regs, &err, NULL);
        Safefree(regbuf);
        if (!ok) croak_dpc("DpcPutRegSet", err);

void
PutRepeat(SV *self, int reg, SV *bufsv)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        DPCHANDLE h = DDD_HANDLE;
        SANE_REGISTER(reg);
        if (!SvPOK(bufsv)) croak("Buffer must be a string");
        STRLEN blen;
        const BYTE *buf = SvPV_const(bufsv, blen);
        if (!MY_CXT.DpcPutRegRepeat(h, reg, buf, blen, &err, NULL))
            croak_dpc("DpcGetRegRepeat", err);

