// Raw mouse input for games under Sikarugir's winemac.drv (#44).
//
// winemac derives the mouse deltas it gives DirectInput and raw input from the macOS cursor
// position: accelerated and floored to whole points, so slow camera turns arrive as 0/±1 steps.
// While the Windows cursor is hidden (mouselook) in the active app, this library freezes the
// macOS cursor, drops winemac's cursor-derived moves and posts GCMouse's unaccelerated device
// counts as winemac relative-move events instead, the way winex11 uses XInput2 raw motion.
//
// winemac.so has no published source and no exports for this, so the event layout and the two
// internal functions are taken from the pinned build below; any other winemac.so leaves the
// library inert. NOTPROTON_RAW_MOUSE=0 opts out (compat_run.sh then does not load it) and
// NOTPROTON_RAW_MOUSE_SCALE multiplies the deltas.
#import <AppKit/AppKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <GameController/GameController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// sikarugir-11.0-r0 lib/wine/x86_64-unix/winemac.so
static const char kWinemacSHA256[] = "b1b103d8d97ae59a78bfccb7078da67a845fc727c4318369154b295be48b1650";
enum {
    kCreateEvent = 0x11210,   // macdrv_event *macdrv_create_event(int type, WineWindow *window)
    kReleaseEvent = 0x106c0,  // void macdrv_release_event(macdrv_event *event)
    kMouseMovedRelative = 0xc,
    kMovedX = 0x18, kMovedY = 0x1c, kMovedDrag = 0x20, kMovedTime = 0x28,
};

typedef void *(*create_event_fn)(int, id);
typedef void (*release_event_fn)(void *);
static create_event_fn create_event;
static release_event_fn release_event;
static IMP original_handleMouseMove, original_setCursorPosition;
static ptrdiff_t wants_hidden_offset;
static double scale = 1, residual_x, residual_y;
static BOOL raw_active;

static void say(const char *fmt, const char *arg) {
    if (getenv("NOTPROTON_RAW_MOUSE_DEBUG")) fprintf(stderr, "rawmouse: %s %s\n", fmt, arg ?: "");
}

static BOOL file_matches(const char *path, const char *hex) {
    NSData *data = [NSData dataWithContentsOfFile:@(path)];
    if (!data) return NO;
    unsigned char md[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, md);
    char got[sizeof(kWinemacSHA256)];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) snprintf(got + 2 * i, 3, "%02x", md[i]);
    return !strcmp(got, hex);
}

// The game window, while the app is frontmost and the Windows cursor is hidden.
static NSWindow *mouselook_window(id controller) {
    // Without a GCMouse nothing would replace the moves winemac's are dropped for.
    if (!controller || !NSApp.isActive || !GCMouse.mice.count) return nil;
    if (!*((BOOL *)((char *)(__bridge void *)controller + wants_hidden_offset))) return nil;
    NSWindow *key = NSApp.keyWindow;
    return [key isKindOfClass:objc_getClass("WineWindow")] ? key : nil;
}

static id controller(void) {
    return ((id (*)(id, SEL))objc_msgSend)(objc_getClass("WineApplicationController"), sel_registerName("sharedController"));
}

static NSWindow *update_raw_state(id ctl) {
    NSWindow *window = mouselook_window(ctl);
    if (!!window != raw_active) {
        raw_active = !!window;
        residual_x = residual_y = 0;
        if (raw_active) {
            // Park the frozen cursor on the game, so clicks cannot land in another window or monitor.
            NSRect frame = window.frame;
            CGFloat top = NSMaxY(NSScreen.screens.firstObject.frame);
            CGWarpMouseCursorPosition(CGPointMake(NSMidX(frame), top - NSMidY(frame)));
        }
        // ponytail: leaving mouselook, winemac resyncs the Windows cursor on the next move.
        CGAssociateMouseAndMouseCursorPosition(!raw_active);
        say(raw_active ? "mouselook on" : "mouselook off", NULL);
    }
    return window;
}

static void raw_moved(float dx, float dy) {
    id ctl = controller();
    NSWindow *window = update_raw_state(ctl);
    if (!window) return;
    residual_x += dx * scale;
    residual_y -= dy * scale;  // GCMouse is y-up, Windows is y-down
    int x = (int)residual_x, y = (int)residual_y;
    if (!x && !y) return;
    residual_x -= x;
    residual_y -= y;
    char *event = create_event(kMouseMovedRelative, window);
    *(int *)(event + kMovedX) = x;
    *(int *)(event + kMovedY) = y;
    *(BOOL *)(event + kMovedDrag) = NSEvent.pressedMouseButtons != 0;
    *(unsigned long *)(event + kMovedTime) = ((unsigned long (*)(id, SEL, NSTimeInterval))objc_msgSend)(
        ctl, sel_registerName("ticksForEventTime:"), NSProcessInfo.processInfo.systemUptime);
    id queue = ((id (*)(id, SEL))objc_msgSend)(window, sel_registerName("queue"));
    ((void (*)(id, SEL, void *))objc_msgSend)(queue, sel_registerName("postEvent:"), event);
    release_event(event);
}

static void handleMouseMove(id self, SEL _cmd, NSEvent *event) {
    if (update_raw_state(self)) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(self, sel_registerName("updateCursor:"), NO);
        return;
    }
    ((void (*)(id, SEL, NSEvent *))original_handleMouseMove)(self, _cmd, event);
}

// winemac reassociates the cursor after each warp (SetCursorPos); keep it frozen in mouselook.
static BOOL setCursorPosition(id self, SEL _cmd, CGPoint pos) {
    BOOL ret = ((BOOL (*)(id, SEL, CGPoint))original_setCursorPosition)(self, _cmd, pos);
    if (raw_active) CGAssociateMouseAndMouseCursorPosition(false);
    return ret;
}

static void release_cursor(void) {
    if (raw_active) CGAssociateMouseAndMouseCursorPosition(true);
}

static void watch(GCMouse *mouse) {
    mouse.handlerQueue = dispatch_get_main_queue();  // raw_moved keeps its state on the main thread
    mouse.mouseInput.mouseMovedHandler = ^(__unused GCMouseInput *input, float dx, float dy) { raw_moved(dx, dy); };
}

static void install(void *base) {
    Class cls = objc_getClass("WineApplicationController");
    Method move = class_getInstanceMethod(cls, sel_registerName("handleMouseMove:"));
    Method warp = class_getInstanceMethod(cls, sel_registerName("setCursorPosition:"));
    Ivar ivar = class_getInstanceVariable(cls, "clientWantsCursorHidden");
    if (!move || !warp || !ivar || !class_getInstanceMethod(cls, sel_registerName("ticksForEventTime:"))) {
        say("winemac does not have the expected classes, staying off", NULL);
        return;
    }
    create_event = (create_event_fn)((char *)base + kCreateEvent);
    release_event = (release_event_fn)((char *)base + kReleaseEvent);
    wants_hidden_offset = ivar_getOffset(ivar);
    original_handleMouseMove = method_setImplementation(move, (IMP)handleMouseMove);
    original_setCursorPosition = method_setImplementation(warp, (IMP)setCursorPosition);
    atexit(release_cursor);
    for (GCMouse *mouse in GCMouse.mice) watch(mouse);
    [NSNotificationCenter.defaultCenter addObserverForName:GCMouseDidConnectNotification object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) { watch(note.object); }];
    [NSNotificationCenter.defaultCenter addObserverForName:NSApplicationDidResignActiveNotification object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) { update_raw_state(controller()); }];
    say("installed", NULL);
}

static void image_added(const struct mach_header *header, __unused intptr_t slide) {
    Dl_info info;
    if (!dladdr(header, &info) || !strstr(info.dli_fname, "/x86_64-unix/winemac.so")) return;
    if (!file_matches(info.dli_fname, kWinemacSHA256)) {
        say("unknown winemac.so, staying off:", info.dli_fname);
        return;
    }
    void *base = (void *)header;
    // winemac registers its classes and starts Cocoa after this callback; the main queue runs once it has.
    dispatch_async(dispatch_get_main_queue(), ^{ install(base); });
}

__attribute__((constructor)) static void init(void) {
    const char *s = getenv("NOTPROTON_RAW_MOUSE_SCALE");
    if (s && atof(s) > 0) scale = atof(s);
    _dyld_register_func_for_add_image(image_added);
}
