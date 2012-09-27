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

struct TRS {
    TRT  trt;
    TRID trid;
    STS  sts;
    ERC  erc;
};


#define LOAD_DPC_FN(fn) do { \
    if (!(MY_CXT.fn = (void *) GetProcAddress(dpcutil, #fn))) \
        croak("missing function: " #fn); \
} while(0)

#define DPC_FN(ret, fn, ...) ret (*fn)(__VA_ARGS__)

typedef struct {
    HMODULE dpcutil;
    DPC_FN(bool, DpcInit, ERC *);
    DPC_FN(void, DpcTerm);
    DPC_FN(bool, DpcGetDpcVersion, char *, ERC *);
    DPC_FN(int,  DvmgGetDevCount, ERC *);
    DPC_FN(void, DvmgStartConfigureDevices, HWND, ERC *);
    DPC_FN(int,  DvmgGetHDVC, char *, ERC *);
    DPC_FN(int,  DvmgGetDefaultDev, ERC *);
    DPC_FN(bool, DvmgGetDevName, int, char *, ERC *);
    DPC_FN(bool, DvmgGetDevType, int, DVCT *, ERC *);
    DPC_FN(bool, DpcOpenData, HANDLE *, char *, ERC *, TRID *);
    DPC_FN(bool, DpcCloseData, HANDLE, ERC *);
    DPC_FN(bool, DpcGetReg, HANDLE, BYTE, BYTE *, ERC *, TRID *);
    DPC_FN(bool, DpcGetRegRepeat, HANDLE, BYTE, BYTE *, int, ERC *, TRID *);
    DPC_FN(bool, DpcPutReg, HANDLE, BYTE, BYTE,   ERC *, TRID *);
    DPC_FN(bool, DpcPutRegRepeat, HANDLE, BYTE, BYTE *, int, ERC *, TRID *);
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
    LOAD_DPC_FN(DpcGetRegRepeat);
    LOAD_DPC_FN(DpcPutReg);
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
Deinit()
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

void *
Open(char *name)
    PREINIT:
        dMY_CXT;
    CODE:
        HANDLE h;
        ERC err;
        if (MY_CXT.DpcOpenData(&h, name, &err, NULL)) {
            RETVAL = h;
        } else {
            croak_dpc("DpcOpenData", err);
        }
    OUTPUT:
        RETVAL

void
Close(void *h)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        if (!MY_CXT.DpcCloseData(h, &err))
            croak_dpc("DpcCloseData", err);

int
Get(void *h, int addr)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        BYTE data;
        if (!MY_CXT.DpcGetReg(h, addr, &data, &err, NULL))
            croak_dpc("DpcGetReg", err);
        RETVAL = data;
    OUTPUT:
        RETVAL

void
GetRepeat(void *h, int reg, SV *bufsv, int count)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        if (count <= 0)
            croak("Negative length");
        if (!SvOK(bufsv))
            sv_setpvs(bufsv, "");
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
Put(void *h, int addr, int data)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        if (!MY_CXT.DpcPutReg(h, addr, data, &err, NULL))
            croak_dpc("DpcPutReg", err);

void
PutRepeat(void *h, int reg, SV *bufsv)
    PREINIT:
        dMY_CXT;
    CODE:
        ERC err;
        if (!SvPOK(bufsv))
            croak("Input is not a string");
        STRLEN blen;
        BYTE *buf = SvPV_const(bufsv, blen);
        if (!MY_CXT.DpcPutRegRepeat(h, reg, buf, blen, &err, NULL))
            croak_dpc("DpcGetRegRepeat", err);

