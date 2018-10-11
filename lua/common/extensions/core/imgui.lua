-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local f = {}

local logTag = "imgui"

local debug = 1

local ffi = require('ffi')
ffi.cdef[[
// FORWARD DECLARATIONS
typedef struct ImFont ImFont;
typedef struct ImFontAtlas ImFontAtlas;
typedef struct ImFontConfig ImFontConfig;
typedef struct ImDrawVert ImDrawVert;
typedef struct ImGuiWindow ImGuiWindow;
// ENUMS
typedef int ImGuiLayoutType;
typedef enum {
  ImGuiLayoutType_Vertical,
  ImGuiLayoutType_Horizontal
} ImGuiLayoutType_;

typedef int ImGuiWindowFlags;
typedef enum {
  ImGuiWindowFlags_NoTitleBar                 = 1 << 0,
  ImGuiWindowFlags_NoResize                   = 1 << 1,
  ImGuiWindowFlags_NoMove                     = 1 << 2,
  ImGuiWindowFlags_NoScrollbar                = 1 << 3,
  ImGuiWindowFlags_NoScrollWithMouse          = 1 << 4,
  ImGuiWindowFlags_NoCollapse                 = 1 << 5,
  ImGuiWindowFlags_AlwaysAutoResize           = 1 << 6,
  ImGuiWindowFlags_NoSavedSettings            = 1 << 8,
  ImGuiWindowFlags_NoInputs                   = 1 << 9,
  ImGuiWindowFlags_MenuBar                    = 1 << 10,
  ImGuiWindowFlags_HorizontalScrollbar        = 1 << 11,
  ImGuiWindowFlags_NoFocusOnAppearing         = 1 << 12,
  ImGuiWindowFlags_NoBringToFrontOnFocus      = 1 << 13,
  ImGuiWindowFlags_AlwaysVerticalScrollbar    = 1 << 14,
  ImGuiWindowFlags_AlwaysHorizontalScrollbar  = 1 << 15,
  ImGuiWindowFlags_AlwaysUseWindowPadding     = 1 << 16,
  ImGuiWindowFlags_ResizeFromAnySide          = 1 << 17,
  ImGuiWindowFlags_ChildWindow                = 1 << 24,
  ImGuiWindowFlags_Tooltip                    = 1 << 25,
  ImGuiWindowFlags_Popup                      = 1 << 26,
  ImGuiWindowFlags_Modal                      = 1 << 27,
  ImGuiWindowFlags_ChildMenu                  = 1 << 28
} ImGuiWindowFlags_;

typedef int ImGuiInputTextFlags;
typedef enum  {
  ImGuiInputTextFlags_CharsDecimal        = 1 << 0,
  ImGuiInputTextFlags_CharsHexadecimal    = 1 << 1,
  ImGuiInputTextFlags_CharsUppercase      = 1 << 2,
  ImGuiInputTextFlags_CharsNoBlank        = 1 << 3,
  ImGuiInputTextFlags_AutoSelectAll       = 1 << 4,
  ImGuiInputTextFlags_EnterReturnsTrue    = 1 << 5,
  ImGuiInputTextFlags_CallbackCompletion  = 1 << 6,
  ImGuiInputTextFlags_CallbackHistory     = 1 << 7,
  ImGuiInputTextFlags_CallbackAlways      = 1 << 8,
  ImGuiInputTextFlags_CallbackCharFilter  = 1 << 9,
  ImGuiInputTextFlags_AllowTabInput       = 1 << 10,
  ImGuiInputTextFlags_CtrlEnterForNewLine = 1 << 11,
  ImGuiInputTextFlags_NoHorizontalScroll  = 1 << 12,
  ImGuiInputTextFlags_AlwaysInsertMode    = 1 << 13,
  ImGuiInputTextFlags_ReadOnly            = 1 << 14,
  ImGuiInputTextFlags_Password            = 1 << 15,
  ImGuiInputTextFlags_NoUndoRedo          = 1 << 16,
  ImGuiInputTextFlags_CharsScientific     = 1 << 17,
  ImGuiInputTextFlags_Multiline           = 1 << 20
} ImGuiInputTextFlags_;

typedef int ImGuiComboFlags;
typedef enum {
  ImGuiComboFlags_PopupAlignLeft  = 1 << 0,
  ImGuiComboFlags_HeightSmall     = 1 << 1,
  ImGuiComboFlags_HeightRegular   = 1 << 2,
  ImGuiComboFlags_HeightLarge     = 1 << 3,
  ImGuiComboFlags_HeightLargest   = 1 << 4,
  ImGuiComboFlags_NoArrowButton   = 1 << 5,
  ImGuiComboFlags_NoPreview       = 1 << 6,
  ImGuiComboFlags_HeightMask_     = ImGuiComboFlags_HeightSmall | ImGuiComboFlags_HeightRegular | ImGuiComboFlags_HeightLarge | ImGuiComboFlags_HeightLargest
} ImGuiComboFlags_;

typedef int ImGuiCol;
typedef enum {
  ImGuiCol_Text,
  ImGuiCol_TextDisabled,
  ImGuiCol_WindowBg,
  ImGuiCol_ChildBg,
  ImGuiCol_PopupBg,
  ImGuiCol_Border,
  ImGuiCol_BorderShadow,
  ImGuiCol_FrameBg,
  ImGuiCol_FrameBgHovered,
  ImGuiCol_FrameBgActive,
  ImGuiCol_TitleBg,
  ImGuiCol_TitleBgActive,
  ImGuiCol_TitleBgCollapsed,
  ImGuiCol_MenuBarBg,
  ImGuiCol_ScrollbarBg,
  ImGuiCol_ScrollbarGrab,
  ImGuiCol_ScrollbarGrabHovered,
  ImGuiCol_ScrollbarGrabActive,
  ImGuiCol_CheckMark,
  ImGuiCol_SliderGrab,
  ImGuiCol_SliderGrabActive,
  ImGuiCol_Button,
  ImGuiCol_ButtonHovered,
  ImGuiCol_ButtonActive,
  ImGuiCol_Header,
  ImGuiCol_HeaderHovered,
  ImGuiCol_HeaderActive,
  ImGuiCol_Separator,
  ImGuiCol_SeparatorHovered,
  ImGuiCol_SeparatorActive,
  ImGuiCol_ResizeGrip,
  ImGuiCol_ResizeGripHovered,
  ImGuiCol_ResizeGripActive,
  ImGuiCol_PlotLines,
  ImGuiCol_PlotLinesHovered,
  ImGuiCol_PlotHistogram,
  ImGuiCol_PlotHistogramHovered,
  ImGuiCol_TextSelectedBg,
  ImGuiCol_ModalWindowDarkening,
  ImGuiCol_DragDropTarget,
  ImGuiCol_NavHighlight,
  ImGuiCol_NavWindowingHighlight,
  ImGuiCol_COUNT
} ImGuiCol_;

typedef int ImDrawCornerFlags;
typedef enum {
  ImDrawCornerFlags_TopLeft   = 1 << 0,
  ImDrawCornerFlags_TopRight  = 1 << 1,
  ImDrawCornerFlags_BotLeft   = 1 << 2,
  ImDrawCornerFlags_BotRight  = 1 << 3,
  ImDrawCornerFlags_Top       = ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_TopRight,
  ImDrawCornerFlags_Bot       = ImDrawCornerFlags_BotLeft | ImDrawCornerFlags_BotRight,
  ImDrawCornerFlags_Left      = ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_BotLeft,
  ImDrawCornerFlags_Right     = ImDrawCornerFlags_TopRight | ImDrawCornerFlags_BotRight,
  ImDrawCornerFlags_All       = 0xF
} ImDrawCornerFlags_;

typedef int ImGuiCond;
typedef enum {
  ImGuiCond_Always        = 1 << 0,
  ImGuiCond_Once          = 1 << 1,
  ImGuiCond_FirstUseEver  = 1 << 2,
  ImGuiCond_Appearing     = 1 << 3
} ImGuiCond_;

typedef int ImGuiSelectableFlags;
typedef enum {
  ImGuiSelectableFlags_DontClosePopups    = 1 << 0,
  ImGuiSelectableFlags_SpanAllColumns     = 1 << 1,
  ImGuiSelectableFlags_AllowDoubleClick   = 1 << 2
} ImGuiSelectableFlags_;

typedef int ImGuiTreeNodeFlags;
typedef enum {
  ImGuiTreeNodeFlags_Selected             = 1 << 0,
  ImGuiTreeNodeFlags_Framed               = 1 << 1,
  ImGuiTreeNodeFlags_AllowItemOverlap     = 1 << 2,
  ImGuiTreeNodeFlags_NoTreePushOnOpen     = 1 << 3,
  ImGuiTreeNodeFlags_NoAutoOpenOnLog      = 1 << 4,
  ImGuiTreeNodeFlags_DefaultOpen          = 1 << 5,
  ImGuiTreeNodeFlags_OpenOnDoubleClick    = 1 << 6,
  ImGuiTreeNodeFlags_OpenOnArrow          = 1 << 7,
  ImGuiTreeNodeFlags_Leaf                 = 1 << 8,
  ImGuiTreeNodeFlags_Bullet               = 1 << 9,
  ImGuiTreeNodeFlags_FramePadding         = 1 << 10,
  ImGuiTreeNodeFlags_NavLeftJumpsBackHere = 1 << 13,
  ImGuiTreeNodeFlags_CollapsingHeader     = ImGuiTreeNodeFlags_Framed | ImGuiTreeNodeFlags_NoAutoOpenOnLog
} ImGuiTreeNodeFlags_;

typedef int ImGuiHoveredFlags;
typedef enum {
  ImGuiHoveredFlags_Default                       = 0,
  ImGuiHoveredFlags_ChildWindows                  = 1 << 0,
  ImGuiHoveredFlags_RootWindow                    = 1 << 1,
  ImGuiHoveredFlags_AnyWindow                     = 1 << 2,
  ImGuiHoveredFlags_AllowWhenBlockedByPopup       = 1 << 3,
  //ImGuiHoveredFlags_AllowWhenBlockedByModal     = 1 << 4,
  ImGuiHoveredFlags_AllowWhenBlockedByActiveItem  = 1 << 5,
  ImGuiHoveredFlags_AllowWhenOverlapped           = 1 << 6,
  ImGuiHoveredFlags_RectOnly                      = ImGuiHoveredFlags_AllowWhenBlockedByPopup | ImGuiHoveredFlags_AllowWhenBlockedByActiveItem | ImGuiHoveredFlags_AllowWhenOverlapped,
  ImGuiHoveredFlags_RootAndChildWindows           = ImGuiHoveredFlags_RootWindow | ImGuiHoveredFlags_ChildWindows
} ImGuiHoveredFlags_;


typedef int ImGuiColorEditFlags;
typedef enum {
  ImGuiColorEditFlags_NoAlpha         = 1 << 1,
  ImGuiColorEditFlags_NoPicker        = 1 << 2,
  ImGuiColorEditFlags_NoOptions       = 1 << 3,
  ImGuiColorEditFlags_NoSmallPreview  = 1 << 4,
  ImGuiColorEditFlags_NoInputs        = 1 << 5,
  ImGuiColorEditFlags_NoTooltip       = 1 << 6,
  ImGuiColorEditFlags_NoLabel         = 1 << 7,
  ImGuiColorEditFlags_NoSidePreview   = 1 << 8,
  ImGuiColorEditFlags_AlphaBar        = 1 << 9,
  ImGuiColorEditFlags_AlphaPreview    = 1 << 10,
  ImGuiColorEditFlags_AlphaPreviewHalf= 1 << 11,
  ImGuiColorEditFlags_HDR             = 1 << 12,
  ImGuiColorEditFlags_RGB             = 1 << 13,
  ImGuiColorEditFlags_HSV             = 1 << 14,
  ImGuiColorEditFlags_HEX             = 1 << 15,
  ImGuiColorEditFlags_Uint8           = 1 << 16,
  ImGuiColorEditFlags_Float           = 1 << 17,
  ImGuiColorEditFlags_PickerHueBar    = 1 << 18,
  ImGuiColorEditFlags_PickerHueWheel  = 1 << 19,
  ImGuiColorEditFlags__InputsMask     = ImGuiColorEditFlags_RGB|ImGuiColorEditFlags_HSV|ImGuiColorEditFlags_HEX,
  ImGuiColorEditFlags__DataTypeMask   = ImGuiColorEditFlags_Uint8|ImGuiColorEditFlags_Float,
  ImGuiColorEditFlags__PickerMask     = ImGuiColorEditFlags_PickerHueWheel|ImGuiColorEditFlags_PickerHueBar,
  ImGuiColorEditFlags__OptionsDefault = ImGuiColorEditFlags_Uint8|ImGuiColorEditFlags_RGB|ImGuiColorEditFlags_PickerHueBar
} ImGuiColorEditFlags_;

typedef int ImGuiKey;
typedef enum {
  ImGuiKey_Tab,
  ImGuiKey_LeftArrow,
  ImGuiKey_RightArrow,
  ImGuiKey_UpArrow,
  ImGuiKey_DownArrow,
  ImGuiKey_PageUp,
  ImGuiKey_PageDown,
  ImGuiKey_Home,
  ImGuiKey_End,
  ImGuiKey_Insert,
  ImGuiKey_Delete,
  ImGuiKey_Backspace,
  ImGuiKey_Space,
  ImGuiKey_Enter,
  ImGuiKey_Escape,
  ImGuiKey_A,
  ImGuiKey_C,
  ImGuiKey_V,
  ImGuiKey_X,
  ImGuiKey_Y,
  ImGuiKey_Z,
  ImGuiKey_COUNT
} ImGuiKey_;

typedef int ImGuiDataType;
typedef enum {
  ImGuiDataType_S32,
  ImGuiDataType_U32,
  ImGuiDataType_S64,
  ImGuiDataType_U64,
  ImGuiDataType_Float,
  ImGuiDataType_Double,
  ImGuiDataType_COUNT
} ImGuiDataType_;

typedef int ImGuiDir;
typedef enum {
    ImGuiDir_None    = -1,
    ImGuiDir_Left    = 0,
    ImGuiDir_Right   = 1,
    ImGuiDir_Up      = 2,
    ImGuiDir_Down    = 3,
    ImGuiDir_COUNT
} ImGuiDir_;

typedef int ImGuiStyleVar;
typedef enum {
  ImGuiStyleVar_Alpha,
  ImGuiStyleVar_WindowPadding,
  ImGuiStyleVar_WindowRounding,
  ImGuiStyleVar_WindowBorderSize,
  ImGuiStyleVar_WindowMinSize,
  ImGuiStyleVar_WindowTitleAlign,
  ImGuiStyleVar_ChildRounding,
  ImGuiStyleVar_ChildBorderSize,
  ImGuiStyleVar_PopupRounding,
  ImGuiStyleVar_PopupBorderSize,
  ImGuiStyleVar_FramePadding,
  ImGuiStyleVar_FrameRounding,
  ImGuiStyleVar_FrameBorderSize,
  ImGuiStyleVar_ItemSpacing,
  ImGuiStyleVar_ItemInnerSpacing,
  ImGuiStyleVar_IndentSpacing,
  ImGuiStyleVar_ScrollbarSize,
  ImGuiStyleVar_ScrollbarRounding,
  ImGuiStyleVar_GrabMinSize,
  ImGuiStyleVar_GrabRounding,
  ImGuiStyleVar_ButtonTextAlign,
  ImGuiStyleVar_COUNT
} ImGuiStyleVar_;

typedef int ImGuiColumnsFlags;
typedef enum {
  ImGuiColumnsFlags_NoBorder              = 1 << 0,
  ImGuiColumnsFlags_NoResize              = 1 << 1,
  ImGuiColumnsFlags_NoPreserveWidths      = 1 << 2,
  ImGuiColumnsFlags_NoForceWithinWindow   = 1 << 3,
  ImGuiColumnsFlags_GrowParentContentsSize= 1 << 4
} ImGuiColumnsFlags_;

typedef int ImGuiDragDropFlags;
typedef enum {
  ImGuiDragDropFlags_SourceNoPreviewTooltip       = 1 << 0,
  ImGuiDragDropFlags_SourceNoDisableHover         = 1 << 1,
  ImGuiDragDropFlags_SourceNoHoldToOpenOthers     = 1 << 2,
  ImGuiDragDropFlags_SourceAllowNullID            = 1 << 3,
  ImGuiDragDropFlags_SourceExtern                 = 1 << 4,
  ImGuiDragDropFlags_AcceptBeforeDelivery         = 1 << 10,
  ImGuiDragDropFlags_AcceptNoDrawDefaultRect      = 1 << 11,
  ImGuiDragDropFlags_AcceptPeekOnly               = ImGuiDragDropFlags_AcceptBeforeDelivery | ImGuiDragDropFlags_AcceptNoDrawDefaultRect
} ImGuiDragDropFlags_;

typedef int ImFontAtlasFlags;
typedef enum {
  ImFontAtlasFlags_NoPowerOfTwoHeight = 1 << 0,
  ImFontAtlasFlags_NoMouseCursors     = 1 << 1
} ImFontAtlasFlags_;

typedef int ImDrawListFlags;
typedef enum {
  ImDrawListFlags_AntiAliasedLines = 1 << 0,
  ImDrawListFlags_AntiAliasedFill  = 1 << 1
} ImDrawListFlags_;

typedef int ImGuiConfigFlags;
typedef enum {
    ImGuiConfigFlags_NavEnableKeyboard      = 1 << 0,
    ImGuiConfigFlags_NavEnableGamepad       = 1 << 1,
    ImGuiConfigFlags_NavEnableSetMousePos   = 1 << 2,
    ImGuiConfigFlags_NavNoCaptureKeyboard   = 1 << 3,
    ImGuiConfigFlags_NoMouse                = 1 << 4,
    ImGuiConfigFlags_NoMouseCursorChange    = 1 << 5,
    ImGuiConfigFlags_IsSRGB                 = 1 << 20,
    ImGuiConfigFlags_IsTouchScreen          = 1 << 21
} ImGuiConfigFlags_;

typedef int ImGuiBackendFlags;
typedef enum {
    ImGuiBackendFlags_HasGamepad            = 1 << 0,
    ImGuiBackendFlags_HasMouseCursors       = 1 << 1,
    ImGuiBackendFlags_HasSetMousePos        = 1 << 2
} ImGuiBackendFlags_;

typedef int ImGuiNavInput;
typedef enum {
    ImGuiNavInput_Activate,
    ImGuiNavInput_Cancel,
    ImGuiNavInput_Input,
    ImGuiNavInput_Menu,
    ImGuiNavInput_DpadLeft,
    ImGuiNavInput_DpadRight,
    ImGuiNavInput_DpadUp,
    ImGuiNavInput_DpadDown,
    ImGuiNavInput_LStickLeft,
    ImGuiNavInput_LStickRight,
    ImGuiNavInput_LStickUp,
    ImGuiNavInput_LStickDown,
    ImGuiNavInput_FocusPrev,
    ImGuiNavInput_FocusNext,
    ImGuiNavInput_TweakSlow,
    ImGuiNavInput_TweakFast,

    ImGuiNavInput_KeyMenu_,
    ImGuiNavInput_KeyLeft_,
    ImGuiNavInput_KeyRight_,
    ImGuiNavInput_KeyUp_,
    ImGuiNavInput_KeyDown_,
    ImGuiNavInput_COUNT,
    ImGuiNavInput_InternalStart_ = ImGuiNavInput_KeyMenu_
} ImGuiNavInput_;

typedef int ImGuiFocusedFlags;
typedef enum {
  ImGuiFocusedFlags_None                          = 0,
  ImGuiFocusedFlags_ChildWindows                  = 1 << 0,
  ImGuiFocusedFlags_RootWindow                    = 1 << 1,
  ImGuiFocusedFlags_AnyWindow                     = 1 << 2,
  ImGuiFocusedFlags_RootAndChildWindows           = ImGuiFocusedFlags_RootWindow | ImGuiFocusedFlags_ChildWindows
} ImGuiFocusedFlags_;

//imgui_internal.h
typedef enum ImGuiInputSource {
  ImGuiInputSource_None = 0,
  ImGuiInputSource_Mouse,
  ImGuiInputSource_Nav,
  ImGuiInputSource_NavKeyboard,
  ImGuiInputSource_NavGamepad,
  ImGuiInputSource_COUNT
} ImGuiInputSource;

typedef enum ImGuiNavForward {
    ImGuiNavForward_None,
    ImGuiNavForward_ForwardQueued,
    ImGuiNavForward_ForwardActive
} ImGuiNavForward;

// #### TYPES #####
typedef signed int          ImS32;
typedef unsigned int        ImU32;
typedef signed   __int64    ImS64;
typedef unsigned __int64    ImU64;
//ifdef _WIN6
typedef unsigned __int64 size_t;
typedef __int64 ptrdiff_t;
typedef __int64 intptr_t;
typedef unsigned short ImWchar;
typedef unsigned short ImDrawIdx;
typedef unsigned int ImGuiID;
typedef int ImGuiItemStatusFlags;
typedef int ImGuiItemFlags;
typedef int ImGuiNavMoveFlags;
typedef int ImGuiMouseCursor;

// ##### STRUCTS #####
typedef struct voidPtr * voidPtr;
typedef struct ImVec2 { float x, y; } ImVec2;
typedef struct ImVec4 { float x, y, z, w; } ImVec4;
typedef struct ImColor { ImVec4 Value; } ImColor;

typedef struct ImTextureID_type * ImTextureID;

typedef struct _iobuf {
  void* _Placeholder;
} FILE;

typedef struct ImVector {
  int Size;
	int Capacity;
  void* Data;
} ImVector;

typedef struct ImFontGlyph {
    ImWchar         Codepoint;
    float           AdvanceX;
    float           X0, Y0, X1, Y1;
    float           U0, V0, U1, V1;
} ImFontGlyph;

typedef struct ImFontConfig {
    void*           FontData;
    int             FontDataSize;
    bool            FontDataOwnedByAtlas;
    int             FontNo;
    float           SizePixels;
    int             OversampleH;
    int             OversampleV;
    bool            PixelSnapH;
    ImVec2          GlyphExtraSpacing;
    ImVec2          GlyphOffset;
    const ImWchar*  GlyphRanges;
    bool            MergeMode;
    unsigned int    RasterizerFlags;
    float           RasterizerMultiply;
    char            Name[40];
    ImFont*         DstFont;
} ImFontConfig;

typedef struct ImFont {
  float                       FontSize;
  float                       Scale;
  ImVec2                      DisplayOffset;
  ImVector/*<ImFontGlyph>*/       Glyphs;
  ImVector/*<float>*/             IndexAdvanceX;
  ImVector/*<unsigned short>*/    IndexLookup;
  const ImFontGlyph*          FallbackGlyph;
  float                       FallbackAdvanceX;
  ImWchar                     FallbackChar;

  short                       ConfigDataCount;
  ImFontConfig*               ConfigData;
  ImFontAtlas*                ContainerAtlas;
  float                       Ascent, Descent;
  bool                        DirtyLookupTables;
  int                         CustomRectIds[1];
} ImFont;

typedef struct ImDrawListSharedData {
  ImVec2          TexUvWhitePixel;
  ImFont*         Font;
  float           FontSize;
  float           CurveTessellationTol;
  ImVec4          ClipRectFullscreen;

  ImVec2          CircleVtx12[12];
} ImDrawListSharedData;

typedef struct ImDrawVert {
  ImVec2  pos;
  ImVec2  uv;
  ImU32   col;
} ImDrawVert;

typedef struct ImDrawList {
  ImVector/*<ImDrawCmd>*/     CmdBuffer;
  ImVector/*<ImDrawIdx>*/     IdxBuffer;
  ImVector/*<ImDrawVert>*/    VtxBuffer;
  ImDrawListFlags             Flags;

  const ImDrawListSharedData* _Data;
  const char*                 _OwnerName;
  unsigned int                _VtxCurrentIdx;
  ImDrawVert*                 _VtxWritePtr;
  ImDrawIdx*                  _IdxWritePtr;
  ImVector/*<ImVec4>*/        _ClipRectStack;
  ImVector/*<ImTextureID>*/   _TextureIdStack;
  ImVector/*<ImVec2>*/        _Path;
  int                         _ChannelsCurrent;
  int                         _ChannelsCount;
  ImVector/*<ImDrawChannel>*/ _Channels;
} ImDrawList;

typedef struct ImGuiTextEditCallbackData {
  ImGuiInputTextFlags EventFlag;
  ImGuiInputTextFlags Flags;
  void*               UserData;
  bool                ReadOnly;

  ImWchar             EventChar;

  ImGuiKey            EventKey;
  char*               Buf;
  int                 BufTextLen;
  int                 BufSize;
  bool                BufDirty;
  int                 CursorPos;
  int                 SelectionStart;
  int                 SelectionEnd;
} ImGuiTextEditCallbackData;

typedef struct ImGuiStyle {
  float       Alpha;
  ImVec2      WindowPadding;
  float       WindowRounding;
  float       WindowBorderSize;
  ImVec2      WindowMinSize;
  ImVec2      WindowTitleAlign;
  float       ChildRounding;
  float       ChildBorderSize;
  float       PopupRounding;
  float       PopupBorderSize;
  ImVec2      FramePadding;
  float       FrameRounding;
  float       FrameBorderSize;
  ImVec2      ItemSpacing;
  ImVec2      ItemInnerSpacing;
  ImVec2      TouchExtraPadding;
  float       IndentSpacing;
  float       ColumnsMinSpacing;
  float       ScrollbarSize;
  float       ScrollbarRounding;
  float       GrabMinSize;
  float       GrabRounding;
  ImVec2      ButtonTextAlign;
  ImVec2      DisplayWindowPadding;
  ImVec2      DisplaySafeAreaPadding;
  bool        AntiAliasedLines;
  bool        AntiAliasedFill;
  float       CurveTessellationTol;
  ImVec4      Colors[ImGuiCol_COUNT];
} ImGuiStyle;

typedef struct ImFontAtlas {
  ImFontAtlasFlags Flags;
  ImTextureID TexID;
  int TexWidth;
  int TexHeight;
} ImFontAtlas;

typedef struct ImGuiIO {
  ImGuiConfigFlags   ConfigFlags;
  ImGuiBackendFlags  BackendFlags;
  ImVec2        DisplaySize;
  float         DeltaTime;
  float         IniSavingRate;
  const char*   IniFilename;
  const char*   LogFilename;
  float         MouseDoubleClickTime;
  float         MouseDoubleClickMaxDist;
  float         MouseDragThreshold;
  int           KeyMap[ImGuiKey_COUNT];
  float         KeyRepeatDelay;
  float         KeyRepeatRate;
  void*         UserData;

  ImFontAtlas*  Fonts;
  float         FontGlobalScale;
  bool          FontAllowUserScaling;
  ImFont*       FontDefault;
  ImVec2        DisplayFramebufferScale;
  ImVec2        DisplayVisibleMin;
  ImVec2        DisplayVisibleMax;

  bool          OptMacOSXBehaviors;
  bool          OptCursorBlink;

  const char* (*GetClipboardTextFn)(void* user_data);
  void        (*SetClipboardTextFn)(void* user_data, const char* text);
  void*       ClipboardUserData;

  void        (*ImeSetInputScreenPosFn)(int x, int y);
  void*       ImeWindowHandle;

  void*       RenderDrawListsFnDummy;

  ImVec2      MousePos;
  bool        MouseDown[5];
  float       MouseWheel;
  float       MouseWheelH;
  bool        MouseDrawCursor;
  bool        KeyCtrl;
  bool        KeyShift;
  bool        KeyAlt;
  bool        KeySuper;
  bool        KeysDown[512];
  ImWchar     InputCharacters[16+1];
  float       NavInputs[ImGuiNavInput_COUNT];

  bool        WantCaptureMouse;
  bool        WantCaptureKeyboard;
  bool        WantTextInput;
  bool        WantSetMousePos;
  bool        WantSaveIniSettings;
  bool        NavActive;
  bool        NavVisible;
  float       Framerate;
  int         MetricsRenderVertices;
  int         MetricsRenderIndices;
  int         MetricsActiveWindows;
  ImVec2      MouseDelta;

  ImVec2      MousePosPrev;
  ImVec2      MouseClickedPos[5];
  float       MouseClickedTime[5];
  bool        MouseClicked[5];
  bool        MouseDoubleClicked[5];
  bool        MouseReleased[5];
  bool        MouseDownOwned[5];
  float       MouseDownDuration[5];
  float       MouseDownDurationPrev[5];
  ImVec2      MouseDragMaxDistanceAbs[5];
  float       MouseDragMaxDistanceSqr[5];
  float       KeysDownDuration[512];
  float       KeysDownDurationPrev[512];
  float       NavInputsDownDuration[ImGuiNavInput_COUNT];
  float       NavInputsDownDurationPrev[ImGuiNavInput_COUNT];
} ImGuiIO;

typedef struct ImGuiStorage{
  struct ImGuiStorage_Pair{
	  ImGuiID key;
	  union { int val_i; float val_f; void* val_p; };
  }Pair;
    ImVector/*<Pair>*/      Data;
}ImGuiStorage;

typedef struct ImRect{
  ImVec2      Min;
  ImVec2      Max;
}ImRect;

typedef struct ImGuiColumnsSet{
  ImGuiID             ID;
  ImGuiColumnsFlags   Flags;
  bool                IsFirstFrame;
  bool                IsBeingResized;
  int                 Current;
  int                 Count;
  float               MinX, MaxX;
  float               LineMinY, LineMaxY;
  float               StartPosY;          // Copy of CursorPos
  float               StartMaxPosX;       // Copy of CursorMaxPos
  ImVector/*<ImGuiColumnData>*/ Columns;
}ImGuiColumnsSet;

typedef struct ImGuiWindowTempData{
  ImVec2                  CursorPos;
  ImVec2                  CursorPosPrevLine;
  ImVec2                  CursorStartPos;
  ImVec2                  CursorMaxPos;
  float                   CurrentLineHeight;
  float                   CurrentLineTextBaseOffset;
  float                   PrevLineHeight;
  float                   PrevLineTextBaseOffset;
  float                   LogLinePosY;
  int                     TreeDepth;
  ImU32                   TreeDepthMayJumpToParentOnPop;
  ImGuiID                 LastItemId;
  ImGuiItemStatusFlags    LastItemStatusFlags;
  ImRect                  LastItemRect;
  ImRect                  LastItemDisplayRect;
  bool                    NavHideHighlightOneFrame;
  bool                    NavHasScroll;
  int                     NavLayerCurrent;
  int                     NavLayerCurrentMask;
  int                     NavLayerActiveMask;
  int                     NavLayerActiveMaskNext;
  bool                    MenuBarAppending;
  ImVec2                  MenuBarOffset;
  ImVector/*<ImGuiWindow*>*/  ChildWindows;
  ImGuiStorage*           StateStorage;
  ImGuiLayoutType         LayoutType;
  ImGuiLayoutType         ParentLayoutType;


  ImGuiItemFlags          ItemFlags;
  float                   ItemWidth;
  float                   TextWrapPos;
  ImVector/*<ImGuiItemFlags>*/ItemFlagsStack;
  ImVector/*<float>*/        ItemWidthStack;
  ImVector/*<float>*/         TextWrapPosStack;
  ImVector/*<ImGuiGroupData>*/ GroupStack;
  int                     StackSizesBackup[6];

  float                   IndentX;
  float                   GroupOffsetX;
  float                   ColumnsOffsetX;
  ImGuiColumnsSet*        ColumnsSet;
} ImGuiWindowTempData;

typedef struct ImGuiMenuColumns{
  int         Count;
  float       Spacing;
  float       Width, NextWidth;
  float       Pos[4], NextWidths[4];
} ImGuiMenuColumns;

typedef struct ImGuiWindow {
  char*                   Name;
  ImGuiID                 ID;
  ImGuiWindowFlags        Flags;
  ImVec2                  Pos;
  ImVec2                  Size;
  ImVec2                  SizeFull;
  ImVec2                  SizeFullAtLastBegin;
  ImVec2                  SizeContents;
  ImVec2                  SizeContentsExplicit;
  ImVec2                  WindowPadding;
  float                   WindowRounding;
  float                   WindowBorderSize;
  ImGuiID                 MoveId;
  ImGuiID                 ChildId;
  ImVec2                  Scroll;
  ImVec2                  ScrollTarget;
  ImVec2                  ScrollTargetCenterRatio;
  ImVec2                  ScrollbarSizes;
  bool                    ScrollbarX, ScrollbarY;
  bool                    Active;
  bool                    WasActive;
  bool                    WriteAccessed;
  bool                    Collapsed;
  bool                    CollapseToggleWanted;
  bool                    SkipItems;
  bool                    Appearing;
  bool                    HasCloseButton;
  int                     BeginOrderWithinParent;
  int                     BeginOrderWithinContext;
  int                     BeginCount;
  ImGuiID                 PopupId;
  int                     AutoFitFramesX, AutoFitFramesY;
  bool                    AutoFitOnlyGrows;
  int                     AutoFitChildAxises;
  ImGuiDir                AutoPosLastDirection;
  int                     HiddenFrames;
  ImGuiCond               SetWindowPosAllowFlags;
  ImGuiCond               SetWindowSizeAllowFlags;
  ImGuiCond               SetWindowCollapsedAllowFlags;
  ImVec2                  SetWindowPosVal;
  ImVec2                  SetWindowPosPivot;

  ImGuiWindowTempData     DC;
  ImVector/*<ImGuiID>*/   IDStack;
  ImRect                  ClipRect;
  ImRect                  OuterRectClipped;
  ImRect                  InnerMainRect, InnerClipRect;
  ImRect                  ContentsRegionRect;
  int                     LastFrameActive;
  float                   ItemWidthDefault;
  ImGuiMenuColumns        MenuColumns;
  ImGuiStorage            StateStorage;
  ImVector/*<ImGuiColumnsSet>*/ ColumnsStorage;
  float                   FontWindowScale;

  ImDrawList*             DrawList;
  ImDrawList              DrawListInst;
  ImGuiWindow*            ParentWindow;
  ImGuiWindow*            RootWindow;
  ImGuiWindow*            RootWindowForTitleBarHighlight;
  ImGuiWindow*            RootWindowForTabbing;
  ImGuiWindow*            RootWindowForNav;

  ImGuiWindow*            NavLastChildNavWindow;
  ImGuiID                 NavLastIds[2];
  ImRect                  NavRectRel[2];

  int                     FocusIdxAllCounter;
  int                     FocusIdxTabCounter;
  int                     FocusIdxAllRequestCurrent;
  int                     FocusIdxTabRequestCurrent;
  int                     FocusIdxAllRequestNext;
  int                     FocusIdxTabRequestNext;
} ImGuiWindow;

typedef struct ImGuiSizeCallback{
  void*   UserData;
  ImVec2  Pos;
  ImVec2  CurrentSize;
  ImVec2  DesiredSize;
} ImGuiSizeCallback;

typedef struct ImGuiNextWindowData{
  ImGuiCond               PosCond;
  ImGuiCond               SizeCond;
  ImGuiCond               ContentSizeCond;
  ImGuiCond               CollapsedCond;
  ImGuiCond               SizeConstraintCond;
  ImGuiCond               FocusCond;
  ImGuiCond               BgAlphaCond;
  ImVec2                  PosVal;
  ImVec2                  PosPivotVal;
  ImVec2                  SizeVal;
  ImVec2                  ContentSizeVal;
  bool                    CollapsedVal;
  ImRect                  SizeConstraintRect;
  ImGuiSizeCallback       SizeCallback;
  void*                   SizeCallbackUserData;
  float                   BgAlphaVal;
  ImVec2                  MenuBarOffsetMinVal;
} ImGuiNextWindowData;

typedef struct ImGuiNavMoveResult{
  ImGuiID       ID;
  ImGuiWindow*  Window;
  float         DistBox;
  float         DistCenter;
  float         DistAxial;
  ImRect        RectRel;
} ImGuiNavMoveResult;

typedef struct ImDrawData{
  bool            Valid;
  ImDrawList**    CmdLists;
  int             CmdListsCount;
  int             TotalIdxCount;
  int             TotalVtxCount;
  ImVec2          DisplayPos;
  ImVec2          DisplaySize;
} ImDrawData;

typedef struct ImDrawDataBuilder {
  ImVector/*<ImDrawList*>*/   Layers[2];
} ImDrawDataBuilder;

typedef struct ImGuiPayload {
  void*           Data;
  int             DataSize;

  ImGuiID         SourceId;
  ImGuiID         SourceParentId;
  int             DataFrameCount;
  char            DataType[32+1];
  bool            Preview;
  bool            Delivery;
} ImGuiPayload;

typedef struct ImGuiTextEditState {
  ImGuiID             Id;
  ImVector/*<ImWchar>*/   Text;
  ImVector/*<char>*/      InitialText;
  ImVector/*<char>*/      TempTextBuffer;
  int                 CurLenA, CurLenW;
  int                 BufSizeA;
  float               ScrollX;
  // ImGuiStb::STB_TexteditState   StbState;
  float               CursorAnim;
  bool                CursorFollow;
  bool                SelectedAllMouseLock;
} ImGuiTextEditState;

typedef struct ImGuiTextBuffer {
  ImVector/*<char>*/      Buf;
} ImGuiTextBuffer;

typedef struct ImGuiContext {
  bool                    Initialized;
    bool                    FontAtlasOwnedByContext;
    ImGuiIO                 IO;
    ImGuiStyle              Style;
    ImFont*                 Font;
    float                   FontSize;
    float                   FontBaseSize;
    ImDrawListSharedData    DrawListSharedData;

    float                   Time;
    int                     FrameCount;
    int                     FrameCountEnded;
    int                     FrameCountRendered;
    ImVector/*<ImGuiWindow*>*/  Windows;
    ImVector/*<ImGuiWindow*>*/  WindowsSortBuffer;
    ImVector/*<ImGuiWindow*>*/  CurrentWindowStack;
    ImGuiStorage            WindowsById;
    int                     WindowsActiveCount;
    ImGuiWindow*            CurrentWindow;
    ImGuiWindow*            HoveredWindow;
    ImGuiWindow*            HoveredRootWindow;
    ImGuiID                 HoveredId;
    bool                    HoveredIdAllowOverlap;
    ImGuiID                 HoveredIdPreviousFrame;
    float                   HoveredIdTimer;
    ImGuiID                 ActiveId;
    ImGuiID                 ActiveIdPreviousFrame;
    float                   ActiveIdTimer;
    bool                    ActiveIdIsAlive;
    bool                    ActiveIdIsJustActivated;
    bool                    ActiveIdAllowOverlap;
    bool                    ActiveIdValueChanged;
    bool                    ActiveIdPreviousFrameIsAlive;
    bool                    ActiveIdPreviousFrameValueChanged;
    int                     ActiveIdAllowNavDirFlags;
    ImVec2                  ActiveIdClickOffset;
    ImGuiWindow*            ActiveIdWindow;
    ImGuiWindow*            ActiveIdPreviousFrameWindow;
    ImGuiInputSource        ActiveIdSource;
    ImGuiID                 LastActiveId;
    float                   LastActiveIdTimer;
    ImGuiWindow*            MovingWindow;
    ImVector/*<ImGuiColMod>*/   ColorModifiers;
    ImVector/*<ImGuiStyleMod>*/ StyleModifiers;
    ImVector/*<ImFont*>*/       FontStack;
    ImVector/*<ImGuiPopupRef>*/ OpenPopupStack;
    ImVector/*<ImGuiPopupRef>*/ CurrentPopupStack;
    ImGuiNextWindowData     NextWindowData;
    bool                    NextTreeNodeOpenVal;
    ImGuiCond               NextTreeNodeOpenCond;

    ImGuiWindow*            NavWindow;
    ImGuiID                 NavId;
    ImGuiID                 NavActivateId;
    ImGuiID                 NavActivateDownId;
    ImGuiID                 NavActivatePressedId;
    ImGuiID                 NavInputId;
    ImGuiID                 NavJustTabbedId;
    ImGuiID                 NavJustMovedToId;
    ImGuiID                 NavNextActivateId;
    ImGuiInputSource        NavInputSource;
    ImRect                  NavScoringRectScreen;
    int                     NavScoringCount;
    ImGuiWindow*            NavWindowingTarget;
    float                   NavWindowingHighlightTimer;
    float                   NavWindowingHighlightAlpha;
    bool                    NavWindowingToggleLayer;
    int                     NavLayer;
    int                     NavIdTabCounter;
    bool                    NavIdIsAlive;
    bool                    NavMousePosDirty;
    bool                    NavDisableHighlight;
    bool                    NavDisableMouseHover;
    bool                    NavAnyRequest;
    bool                    NavInitRequest;
    bool                    NavInitRequestFromMove;
    ImGuiID                 NavInitResultId;
    ImRect                  NavInitResultRectRel;
    bool                    NavMoveFromClampedRefRect;
    bool                    NavMoveRequest;
    ImGuiNavMoveFlags       NavMoveRequestFlags;
    ImGuiNavForward         NavMoveRequestForward;
    ImGuiDir                NavMoveDir, NavMoveDirLast;
    ImGuiDir                NavMoveClipDir;
    ImGuiNavMoveResult      NavMoveResultLocal;
    ImGuiNavMoveResult      NavMoveResultLocalVisibleSet;
    ImGuiNavMoveResult      NavMoveResultOther;

    ImDrawData              DrawData;
    ImDrawDataBuilder       DrawDataBuilder;
    float                   ModalWindowDarkeningRatio;
    ImDrawList              OverlayDrawList;
    ImGuiMouseCursor        MouseCursor;

    bool                    DragDropActive;
    ImGuiDragDropFlags      DragDropSourceFlags;
    int                     DragDropMouseButton;
    ImGuiPayload            DragDropPayload;
    ImRect                  DragDropTargetRect;
    ImGuiID                 DragDropTargetId;
    ImGuiDragDropFlags      DragDropAcceptFlags;
    float                   DragDropAcceptIdCurrRectSurface;
    ImGuiID                 DragDropAcceptIdCurr;
    ImGuiID                 DragDropAcceptIdPrev;
    int                     DragDropAcceptFrameCount;
    ImVector/*<unsigned char>*/ DragDropPayloadBufHeap;
    unsigned char           DragDropPayloadBufLocal[8];

    ImGuiTextEditState      InputTextState;
    ImFont                  InputTextPasswordFont;
    ImGuiID                 ScalarAsInputTextId;
    ImGuiColorEditFlags     ColorEditOptions;
    ImVec4                  ColorPickerRef;
    bool                    DragCurrentAccumDirty;
    float                   DragCurrentAccum;
    float                   DragSpeedDefaultRatio;
    ImVec2                  ScrollbarClickDeltaToGrabCenter;
    int                     TooltipOverrideCount;
    ImVector/*<char>*/         PrivateClipboard;
    ImVec2                  PlatformImePos, PlatformImeLastPos;

    bool                           SettingsLoaded;
    float                          SettingsDirtyTimer;
    ImGuiTextBuffer                SettingsIniData;
    ImVector/*<ImGuiSettingsHandler>*/ SettingsHandlers;
    ImVector/*<ImGuiWindowSettings>*/  SettingsWindows;

    bool                    LogEnabled;
    FILE*                   LogFile;
    ImGuiTextBuffer         LogClipboard;
    int                     LogStartDepth;
    int                     LogAutoExpandMaxDepth;

    float                   FramerateSecPerFrame[120];
    int                     FramerateSecPerFrameIdx;
    float                   FramerateSecPerFrameAccum;
    int                     WantCaptureMouseNextFrame;
    int                     WantCaptureKeyboardNextFrame;
    int                     WantTextInputNextFrame;
    char                    TempBuffer[1024*3+1];
} ImGuiContext;

typedef struct ImGuiListClipper {
    float   StartPosY;
    float   ItemsHeight;
    int     ItemsCount, StepNo, DisplayStart, DisplayEnd;
} ImGuiListClipper;

typedef struct ImGuiTextFilter {
  struct ImGuiTextFilter_TextRange{
    const char* b;
    const char* e;
  } TextRange;

  char                    InputBuf[256];
  ImVector/*<TextRange>*/ Filters;
  int                     CountGrep;
} ImGuiTextFilter;

typedef int (*ImGuiTextEditCallback)(ImGuiTextEditCallbackData *data);

// Main
ImGuiContext* ImGui_CreateContext();
ImGuiContext* ImGui_GetMainContext();
void ImGui_NewFrame(ImGuiContext* ctx);
void ImGui_registerDrawData(ImGuiContext* ctx);
void imgui_SetCurrentContext(ImGuiContext* ctx);
ImGuiIO* imgui_CreateIO(ImGuiContext& g);
void imgui_GetIO(ImGuiContext& g, ImGuiIO* res);
void imgui_GetStyle(ImGuiContext& g, ImGuiStyle* res);
// Demo, Debug, Information
void imgui_ShowDemoWindow(ImGuiContext& g, bool* p_open);
void imgui_ShowMetricsWindow(ImGuiContext& g, bool* p_open);
void imgui_ShowStyleEditor(ImGuiContext& g, ImGuiStyle* ref);
bool imgui_ShowStyleSelector(ImGuiContext& g, const char* label);
void imgui_ShowFontSelector(ImGuiContext& g, const char* label);
void imgui_ShowUserGuide(ImGuiContext& g);
const char* imgui_GetVersion();
// Styles
void imgui_StyleColorsDark(ImGuiContext& g, ImGuiStyle* dst);
void imgui_StyleColorsClassic(ImGuiContext& g, ImGuiStyle* dst);
void imgui_StyleColorsLight(ImGuiContext& g, ImGuiStyle* dst);
// Windows
bool imgui_Begin(ImGuiContext& g, const char* name, bool* p_open, ImGuiWindowFlags flags);
void imgui_End(ImGuiContext& g);
bool imgui_BeginChild1(ImGuiContext& g, const char* str_id, const ImVec2& size, bool border, ImGuiWindowFlags flags);
bool imgui_BeginChild2(ImGuiContext& g, ImGuiID id, const ImVec2& size, bool border, ImGuiWindowFlags flags);
void imgui_EndChild(ImGuiContext& g);
// Windows: Utilities
bool imgui_IsWindowAppearing(ImGuiContext& g);
bool imgui_IsWindowCollapsed(ImGuiContext& g);
bool imgui_IsWindowFocused(ImGuiContext& g, ImGuiFocusedFlags flags);
bool imgui_IsWindowHovered(ImGuiContext& g, ImGuiFocusedFlags flags);
ImDrawList* imgui_GetWindowDrawList(ImGuiContext& g);
void imgui_GetWindowPos(ImGuiContext& g, ImVec2* res);
void imgui_GetWindowSize(ImGuiContext& g, ImVec2* res);
float imgui_GetWindowWidth(ImGuiContext& g);
float imgui_GetWindowHeight(ImGuiContext& g);
void imgui_GetContentRegionMax(ImGuiContext& g, ImVec2* res);
void imgui_GetContentRegionAvail(ImGuiContext& g, ImVec2* res);
float imgui_GetContentRegionAvailWidth(ImGuiContext& g);
void imgui_GetWindowContentRegionMin(ImGuiContext& g, ImVec2* res);
void imgui_GetWindowContentRegionMax(ImGuiContext& g, ImVec2* res);
float imgui_GetWindowContentRegionWidth(ImGuiContext& g);

void imgui_SetNextWindowPos(ImGuiContext& g, const ImVec2& pos, ImGuiCond cond, const ImVec2& pivot);
void imgui_SetNextWindowSize(ImGuiContext& g, const ImVec2& size, ImGuiCond cond);
void imgui_SetNextWindowSizeConstraints(ImGuiContext& g, const ImVec2& size_min, const ImVec2& size_max, ImGuiSizeCallback custom_callback, void* custom_callback_data);
void imgui_SetNextWindowContentSize(ImGuiContext& g, const ImVec2& size);
void imgui_SetNextWindowCollapsed(ImGuiContext& g, bool collapsed, ImGuiCond cond);
void imgui_SetNextWindowFocus(ImGuiContext& g);
void imgui_SetNextWindowBgAlpha(ImGuiContext& g, float alpha);
void imgui_SetWindowPos1(ImGuiContext& g, const ImVec2& pos, ImGuiCond cond);
void imgui_SetWindowSize1(ImGuiContext& g, const ImVec2& size, ImGuiCond cond);
void imgui_SetWindowCollapsed1(ImGuiContext& g, bool collapsed, ImGuiCond cond);
void imgui_SetWindowFocus1(ImGuiContext& g);
void imgui_SetWindowFontScale(ImGuiContext& g, float scale);
void imgui_SetWindowPos2(ImGuiContext& g, const char* name, const ImVec2& pos, ImGuiCond cond);
void imgui_SetWindowSize2(ImGuiContext& g, const char* name, const ImVec2& size, ImGuiCond cond);
void imgui_SetWindowCollapsed2(ImGuiContext& g, const char* name, bool collapsed, ImGuiCond cond);
void imgui_SetWindowFocus2(ImGuiContext& g, const char* name);
//Windows Scrolling
float imgui_GetScrollX(ImGuiContext& g);
float imgui_GetScrollY(ImGuiContext& g);
float imgui_GetScrollMaxX(ImGuiContext& g);
float imgui_GetScrollMaxY(ImGuiContext& g);
void imgui_SetScrollX(ImGuiContext& g, float scroll_x);
void imgui_SetScrollY(ImGuiContext& g, float scroll_y);
void imgui_SetScrollHere(ImGuiContext& g, float center_y_ratio);
void imgui_SetScrollFromPosY(ImGuiContext& g, float pos_y, float center_y_ratio);
// Parameters stacks (shared)
void imgui_PushFont(ImGuiContext& g, ImFont* font);
void imgui_PopFont(ImGuiContext& g);
void imgui_PushStyleColor1(ImGuiContext& g, ImGuiCol idx, ImU32 col);
void imgui_PushStyleColor2(ImGuiContext& g, ImGuiCol idx, const ImVec4& col);
void imgui_PopStyleColor(ImGuiContext& g, int count);
void imgui_PushStyleVar1(ImGuiContext& g, ImGuiStyleVar idx, float val);
void imgui_PushStyleVar2(ImGuiContext& g, ImGuiStyleVar idx, const ImVec2& val);
void imgui_PopStyleVar(ImGuiContext& g, int count);
const ImVec4& imgui_GetStyleColorVec4(ImGuiContext& g, ImGuiCol idx);
ImFont* imgui_GetFont(ImGuiContext& g);
float imgui_GetFontSize(ImGuiContext& g);
void imgui_GetFontTexUvWhitePixel(ImGuiContext& g, ImVec2* res);
ImU32 imgui_GetColorU321(ImGuiContext& g, ImGuiCol idx, float alpha_mul);
ImU32 imgui_GetColorU322(ImGuiContext& g, const ImVec4& col);
ImU32 imgui_GetColorU323(ImGuiContext& g, ImU32 col);
// Parameters stacks (current window)
void imgui_PushItemWidth(ImGuiContext& g, float item_width);
void imgui_PopItemWidth(ImGuiContext& g);
float imgui_CalcItemWidth(ImGuiContext& g);
void imgui_PushTextWrapPos(ImGuiContext& g, float wrap_pos_x);
void imgui_PopTextWrapPos(ImGuiContext& g);
void imgui_PushAllowKeyboardFocus(ImGuiContext& g, bool allow_keyboard_focus);
void imgui_PopAllowKeyboardFocus(ImGuiContext& g);
void imgui_PushButtonRepeat(ImGuiContext& g, bool repeat);
void imgui_PopButtonRepeat(ImGuiContext& g);
// Cursor / Layout
bool imgui_Separator(ImGuiContext& g);
void imgui_SameLine(ImGuiContext& g, float pos_x, float spacing_w);
void imgui_NewLine(ImGuiContext& g);
void imgui_Spacing(ImGuiContext& g);
void imgui_Dummy(ImGuiContext& g, const ImVec2& size);
void imgui_Indent(ImGuiContext& g, float indent_w);
void imgui_Unindent(ImGuiContext& g, float indent_w);
void imgui_BeginGroup(ImGuiContext& g);
void imgui_EndGroup(ImGuiContext& g);
void imgui_GetCursorPos(ImGuiContext& g, ImVec2* res);
float imgui_GetCursorPosX(ImGuiContext& g);
float imgui_GetCursorPosY(ImGuiContext& g);
void imgui_SetCursorPos(ImGuiContext& g, const ImVec2& local_pos);
void imgui_SetCursorPosX(ImGuiContext& g, float x);
void imgui_SetCursorPosY(ImGuiContext& g, float y);
void imgui_GetCursorStartPos(ImGuiContext& g, ImVec2* res);
void imgui_GetCursorScreenPos(ImGuiContext& g, ImVec2* res);
void imgui_SetCursorScreenPos(ImGuiContext& g, const ImVec2& screen_pos);
void imgui_AlignTextToFramePadding(ImGuiContext& g);
float imgui_GetTextLineHeight(ImGuiContext& g);
float imgui_GetTextLineHeightWithSpacing(ImGuiContext& g);
float imgui_GetFrameHeight(ImGuiContext& g);
float imgui_GetFrameHeightWithSpacing(ImGuiContext& g);
// ID stack/scopes
void imgui_PushID1(ImGuiContext& g, const char* str_id);
void imgui_PushID2(ImGuiContext& g, const char* str_id_begin, const char* str_id_end);
void imgui_PushID3(ImGuiContext& g, const void* ptr_id);
void imgui_PushID4(ImGuiContext& g, int int_id);
void imgui_PopID(ImGuiContext& g);
void imgui_GetID1(ImGuiContext& g, const char* str_id);
void imgui_GetID2(ImGuiContext& g, const char* str_id_begin, const char* str_id_end);
void imgui_GetID3(ImGuiContext& g, const void* ptr_id);
// Widgets: Text
void imgui_TextUnformatted(ImGuiContext& g, const char* text, const char* text_end);
void imgui_Text(ImGuiContext& g, const char* fmt, ...);
void imgui_TextColored(ImGuiContext& g, const ImVec4& col, const char* fmt, ...);
void imgui_TextDisabled(ImGuiContext& g, const char* fmt, ...);
void imgui_TextWrapped(ImGuiContext& g, const char* fmt, ...);
void imgui_LabelText(ImGuiContext& g, const char* label, const char* fmt, ...);
void imgui_BulletText(ImGuiContext& g, const char* fmt, ...);
// Widgets: Main
bool imgui_Button(ImGuiContext& g, const char* label, const ImVec2* size);
bool imgui_SmallButton(ImGuiContext& g, const char* label);
bool imgui_ArrowButton(ImGuiContext& g, const char* str_id, ImGuiDir dir);
bool imgui_InvisibleButton(ImGuiContext& g, const char* str_id, const ImVec2& size);
void imgui_Image(ImGuiContext& g, ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0, const ImVec2& uv1, const ImVec4& tint_col, const ImVec4& border_col);
bool imgui_ImageButton(ImGuiContext& g, ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0, const ImVec2& uv1, int frame_padding, const ImVec4& bg_col, const ImVec4& tint_col);
bool imgui_Checkbox(ImGuiContext& g, const char* label, bool* v);
bool imgui_CheckboxFlags(ImGuiContext& g, const char* label, unsigned int* flags, unsigned int flags_value);
bool imgui_RadioButton1(ImGuiContext& g, const char* label, bool active);
bool imgui_RadioButton2(ImGuiContext& g, const char* label, int* v, int v_button);
void imgui_PlotLines1(ImGuiContext& g, const char* label, const float* values, int values_count, int values_offset, const char* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
void imgui_PlotLines2(ImGuiContext& g, const char* label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset, const char* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
void imgui_PlotHistogram1(ImGuiContext& g, const char* label, const float* values, int values_count, int values_offset, const char* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
void imgui_PlotHistogram2(ImGuiContext& g, const char* label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset, const char* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
void imgui_ProgressBar(ImGuiContext& g, float fraction, const ImVec2& size_arg, const char* overlay);
void imgui_Bullet(ImGuiContext& g);
// Widgets: Combo Box
bool imgui_BeginCombo(ImGuiContext& g, const char* label, const char* preview_value, ImGuiComboFlags flags);
void imgui_EndCombo(ImGuiContext& g);
bool imgui_Combo1(ImGuiContext& g, const char* label, int* current_item, const char* const items[], int items_count, int popup_max_height_in_items);
bool imgui_Combo2(ImGuiContext& g, const char* label, int* current_item, const char* items_separated_by_zeros, int popup_max_height_in_items);
// Widgets: Drags
bool imgui_DragFloat(ImGuiContext& g, const char* label, float* v, float v_speed, float v_min, float v_max, const char* format, float power);
bool imgui_DragFloat2(ImGuiContext& g, const char* label, float v[2], float v_speed, float v_min, float v_max, const char* format, float power);
bool imgui_DragFloat3(ImGuiContext& g, const char* label, float v[3], float v_speed, float v_min, float v_max, const char* format, float power);
bool imgui_DragFloat4(ImGuiContext& g, const char* label, float v[4], float v_speed, float v_min, float v_max, const char* format, float power);
bool imgui_DragFloatRange2(ImGuiContext& g, const char* label, float* v_current_min, float* v_current_max, float v_speed, float v_min, float v_max, const char* format, const char* format_max, float power);
bool imgui_DragInt(ImGuiContext& g, const char* label, int* v, float v_speed, int v_min, int v_max, const char* format);
bool imgui_DragInt2(ImGuiContext& g, const char* label, int v[2], float v_speed, int v_min, int v_max, const char* format);
bool imgui_DragInt3(ImGuiContext& g, const char* label, int v[3], float v_speed, int v_min, int v_max, const char* format);
bool imgui_DragInt4(ImGuiContext& g, const char* label, int v[4], float v_speed, int v_min, int v_max, const char* format);
bool imgui_DragIntRange2(ImGuiContext& g, const char* label, int* v_current_min, int* v_current_max, float v_speed, int v_min, int v_max, const char* format, const char* format_max);
bool imgui_DragScalar(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, float v_speed, const void* v_min, const void* v_max, const char* format, float power);
bool imgui_DragScalarN(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, int components, float v_speed, const void* v_min, const void* v_max, const char* format, float power);
// Widgets: Input with Keyboard
bool imgui_InputText(ImGuiContext& g, const char* label, char* buf, int buf_size, ImGuiInputTextFlags flags, ImGuiTextEditCallback callback, void* user_data);
bool imgui_InputTextMultiline(ImGuiContext& g, const char* label, char* buf, size_t buf_size, const ImVec2& size, ImGuiInputTextFlags flags, ImGuiTextEditCallback callback, void* user_data);
bool imgui_InputTextMultilineReadOnly(ImGuiContext& g, const char* label, const char* buf, const ImVec2& size, ImGuiInputTextFlags flags, ImGuiTextEditCallback callback, void* user_data);
bool imgui_InputFloat(ImGuiContext& g, const char* label, float* v, float step, float step_fast, const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputFloat2(ImGuiContext& g, const char* label, float v[2], const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputFloat3(ImGuiContext& g, const char* label, float v[3], const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputFloat4(ImGuiContext& g, const char* label, float v[4], const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputInt(ImGuiContext& g, const char* label, int* v, int step, int step_fast, ImGuiInputTextFlags extra_flags);
bool imgui_InputInt2(ImGuiContext& g, const char* label, int v[2], ImGuiInputTextFlags extra_flags);
bool imgui_InputInt3(ImGuiContext& g, const char* label, int v[2], ImGuiInputTextFlags extra_flags);
bool imgui_InputInt4(ImGuiContext& g, const char* label, int v[2], ImGuiInputTextFlags extra_flags);
bool imgui_InputDouble(ImGuiContext& g, const char* label, double* v, double step, double step_fast, const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputScalar(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, const void* step, const void* step_fast, const char* format, ImGuiInputTextFlags extra_flags);
bool imgui_InputScalarN(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, int components, const void* step, const void* step_fast, const char* format, ImGuiInputTextFlags extra_flags);
// Widgets: Sliders
bool imgui_SliderFloat(ImGuiContext& g, const char* label, float* v, float v_min, float v_max, const char* format, float power);
bool imgui_SliderFloat2(ImGuiContext& g, const char* label, float v[2], float v_min, float v_max, const char* format, float power);
bool imgui_SliderFloat3(ImGuiContext& g, const char* label, float v[3], float v_min, float v_max, const char* format, float power);
bool imgui_SliderFloat4(ImGuiContext& g, const char* label, float v[4], float v_min, float v_max, const char* format, float power);
bool imgui_SliderAngle(ImGuiContext& g, const char* label, float* v_rad, float v_degrees_min, float v_degrees_max);
bool imgui_SliderInt(ImGuiContext& g, const char* label, int* v, int v_min, int v_max, const char* format);
bool imgui_SliderInt2(ImGuiContext& g, const char* label, int v[2], int v_min, int v_max, const char* format);
bool imgui_SliderInt3(ImGuiContext& g, const char* label, int v[3], int v_min, int v_max, const char* format);
bool imgui_SliderInt4(ImGuiContext& g, const char* label, int v[4], int v_min, int v_max, const char* format);
bool imgui_SliderScalar(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, const void* v_min, const void* v_max, const char* format, float power);
bool imgui_SliderScalarN(ImGuiContext& g, const char* label, ImGuiDataType data_type, void* v, int components, const void* v_min, const void* v_max, const char* format, float power);
bool imgui_VSliderFloat(ImGuiContext& g, const char* label, const ImVec2& size, float* v, float v_min, float v_max, const char* format, float power);
bool imgui_VSliderInt(ImGuiContext& g, const char* label, const ImVec2& size, int* v, int v_min, int v_max, const char* format);
bool imgui_VSliderScalar(ImGuiContext& g, const char* label, const ImVec2& size, ImGuiDataType data_type, void* v, const void* v_min, const void* v_max, const char* format, float power);
// Widgets: Color Editor/Picker
bool imgui_ColorEdit3(ImGuiContext& g, const char* label, float col[3], ImGuiColorEditFlags flags);
bool imgui_ColorEdit4(ImGuiContext& g, const char* label, float col[4], ImGuiColorEditFlags flags);
bool imgui_ColorPicker3(ImGuiContext& g, const char* label, float col[3], ImGuiColorEditFlags flags);
bool imgui_ColorPicker4(ImGuiContext& g, const char* label, float col[4], ImGuiColorEditFlags flags, const float* ref_col);
bool imgui_ColorButton(ImGuiContext& g, const char* desc_id, const ImVec4& col, ImGuiColorEditFlags flags, ImVec2 size);
void imgui_SetColorEditOptions(ImGuiContext& g, ImGuiColorEditFlags flags);
// Widgets: Trees
bool imgui_TreeNode1(ImGuiContext& g, const char* label);
bool imgui_TreeNode2(ImGuiContext& g, const char* str_id, const char* fmt, ...);
bool imgui_TreeNode3(ImGuiContext& g, const void* ptr_id, const char* fmt, ...);
bool imgui_TreeNodeV1(ImGuiContext& g, const char* str_id, const char* fmt, ...);
bool imgui_TreeNodeV2(ImGuiContext& g, const void* ptr_id, const char* fmt, ...);
bool imgui_TreeNodeEx1(ImGuiContext& g, const char* label, ImGuiTreeNodeFlags flags);
bool imgui_TreeNodeEx2(ImGuiContext& g, const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, ...);
bool imgui_TreeNodeEx3(ImGuiContext& g, const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, ...);
bool imgui_TreeNodeExV1(ImGuiContext& g, const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, ...);
bool imgui_TreeNodeExV2(ImGuiContext& g, const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, ...);
void imgui_TreePush1(ImGuiContext& g, const char* str_id);
void imgui_TreePush2(ImGuiContext& g, const void* ptr_id);
void imgui_TreePop(ImGuiContext& g);
void imgui_TreeAdvanceToLabelPos(ImGuiContext& g);
float imgui_GetTreeNodeToLabelSpacing(ImGuiContext& g);
void imgui_SetNextTreeNodeOpen(ImGuiContext& g, bool is_open, ImGuiCond cond);
bool imgui_CollapsingHeader1(ImGuiContext& g, const char* label, ImGuiTreeNodeFlags flags);
bool imgui_CollapsingHeader2(ImGuiContext& g, const char* label, bool* p_open, ImGuiTreeNodeFlags flags);
// Widgets: Selectable / Lists
bool imgui_Selectable1(ImGuiContext& g, const char* label, bool selected, ImGuiSelectableFlags flags, const ImVec2& size);
bool imgui_Selectable2(ImGuiContext& g, const char* label, bool* p_selected, ImGuiSelectableFlags flags, const ImVec2& size);
bool imgui_ListBox(ImGuiContext& g, const char* label, int* current_item, const char* const items[], int items_count, int height_in_items);
bool imgui_ListBoxHeader1(ImGuiContext& g, const char* label, const ImVec2& size);
bool imgui_ListBoxHeader2(ImGuiContext& g, const char* label, int items_count, int height_in_items);
void imgui_ListBoxFooter(ImGuiContext& g);
// Widgets: Value() Helpers
void imgui_Value1(ImGuiContext& g, const char* prefix, bool b);
void imgui_Value2(ImGuiContext& g, const char* prefix, int v);
void imgui_Value3(ImGuiContext& g, const char* prefix, unsigned int v);
void imgui_Value4(ImGuiContext& g, const char* prefix, float v, const char* float_format);
// Tooltips
void imgui_SetTooltip(ImGuiContext& g, const char* fmt, ...);
void imgui_BeginTooltip(ImGuiContext& g);
void imgui_EndTooltip(ImGuiContext& g);
// Menus
bool imgui_BeginMainMenuBar(ImGuiContext& g);
void imgui_EndMainMenuBar(ImGuiContext& g);
bool imgui_BeginMenuBar(ImGuiContext& g);
void imgui_EndMenuBar(ImGuiContext& g);
bool imgui_BeginMenu(ImGuiContext& g, const char* label, bool enabled);
void imgui_EndMenu(ImGuiContext& g);
bool imgui_MenuItem1(ImGuiContext& g, const char* label, const char* shortcut, bool selected, bool enabled);
bool imgui_MenuItem2(ImGuiContext& g, const char* label, const char* shortcut, bool* p_selected, bool enabled);
// Popups
void imgui_OpenPopup(ImGuiContext& g, const char* str_id);
bool imgui_BeginPopup(ImGuiContext& g, const char* str_id, ImGuiWindowFlags flags);
bool imgui_BeginPopupContextItem(ImGuiContext& g, const char* str_id, int mouse_button);
bool imgui_BeginPopupContextWindow(ImGuiContext& g, const char* str_id, int mouse_button, bool also_over_items);
bool imgui_BeginPopupContextVoid(ImGuiContext& g, const char* str_id, int mouse_button);
bool imgui_BeginPopupModal(ImGuiContext& g, const char* name, bool* p_open, ImGuiWindowFlags flags);
void imgui_EndPopup(ImGuiContext& g);
bool imgui_OpenPopupOnItemClick(ImGuiContext& g, const char* str_id, int mouse_button);
bool imgui_IsPopupOpen(ImGuiContext& g, const char* str_id);
void imgui_CloseCurrentPopup(ImGuiContext& g);
// Columns
void imgui_Columns(ImGuiContext& g, int count, const char* id, bool border);
void imgui_NextColumn(ImGuiContext& g);
int imgui_GetColumnIndex(ImGuiContext& g);
float imgui_GetColumnWidth(ImGuiContext& g, int column_index);
void imgui_SetColumnWidth(ImGuiContext& g, int column_index, float width);
float imgui_GetColumnOffset(ImGuiContext& g, int column_index);
void imgui_SetColumnOffset(ImGuiContext& g, int column_index, float offset_x);
int imgui_GetColumnsCount(ImGuiContext& g);
void imgui_BeginColumns(ImGuiContext& g, const char* str_id, int count, ImGuiColumnsFlags flags);
void imgui_EndColumns(ImGuiContext& g);
// Logging/Capture
void imgui_LogToTTY(ImGuiContext& g, int max_depth);
void imgui_LogToFile(ImGuiContext& g, int max_depth, const char* filename);
void imgui_LogToClipboard(ImGuiContext& g, int max_depth);
void imgui_LogFinish(ImGuiContext& g);
void imgui_LogButtons(ImGuiContext& g);
void imgui_LogText(ImGuiContext& g, const char* fmt, ...);
// Drag and Drop
bool imgui_BeginDragDropSource(ImGuiContext& g, ImGuiDragDropFlags flags);
bool imgui_SetDragDropPayload(ImGuiContext& g, const char* type, const void* data, size_t size, ImGuiCond cond);
void imgui_EndDragDropSource(ImGuiContext& g);
bool imgui_BeginDragDropTarget(ImGuiContext& g);
const ImGuiPayload* imgui_AcceptDragDropPayload(ImGuiContext& g, const char* type, ImGuiDragDropFlags flags);
void imgui_EndDragDropTarget(ImGuiContext& g);
// Clipping
void imgui_PushClipRect(ImGuiContext& g, const ImVec2& clip_rect_min, const ImVec2& clip_rect_max, bool intersect_with_current_clip_rect);
void imgui_PopClipRect(ImGuiContext& g);
// Focus, Activation
void imgui_SetItemDefaultFocus(ImGuiContext& g);
void imgui_SetKeyboardFocusHere(ImGuiContext& g, int offset);
// Utilities
bool imgui_IsItemHovered(ImGuiContext& g, ImGuiHoveredFlags flags);
bool imgui_IsItemActive(ImGuiContext& g);
bool imgui_IsItemFocused(ImGuiContext& g);
bool imgui_IsItemClicked(ImGuiContext& g, int mouse_button);
bool imgui_IsItemVisible(ImGuiContext& g);
bool imgui_IsItemDeactivated(ImGuiContext& g);
bool imgui_IsItemDeactivatedAfterChange(ImGuiContext& g);
bool imgui_IsAnyItemHovered(ImGuiContext& g);
bool imgui_IsAnyItemActive(ImGuiContext& g);
bool imgui_IsAnyItemFocused(ImGuiContext& g);
void imgui_GetItemRectMin(ImGuiContext& g, ImVec2* res);
void imgui_GetItemRectMax(ImGuiContext& g, ImVec2* res);
void imgui_GetItemRectSize(ImGuiContext& g, ImVec2* v);
void imgui_SetItemAllowOverlap(ImGuiContext& g);
bool imgui_IsRectVisible1(ImGuiContext& g, const ImVec2& size);
bool imgui_IsRectVisible2(ImGuiContext& g, const ImVec2& rect_min, const ImVec2& rect_max);
float imgui_GetTime(ImGuiContext& g);
int imgui_GetFrameCount(ImGuiContext& g);
ImDrawList* imgui_GetOverlayDrawList(ImGuiContext& g);
ImDrawListSharedData* imgui_GetDrawListSharedData(ImGuiContext& g);
const char* imgui_GetStyleColorName(ImGuiCol idx);
void imgui_SetStateStorage(ImGuiContext& g, ImGuiStorage* storage);
ImGuiStorage* imgui_GetStateStorage(ImGuiContext& g);
void imgui_CalcTextSize(ImGuiContext& g, ImVec2* res, const char* text, const char* text_end, bool hide_text_after_double_hash, float wrap_width);
void imgui_CalcListClipping(ImGuiContext& g, int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);

bool imgui_BeginChildFrame(ImGuiContext& g, ImGuiID id, const ImVec2& size, ImGuiWindowFlags flags);
void imgui_EndChildFrame(ImGuiContext& g);

void imgui_ColorConvertU32ToFloat4(ImVec4* res, ImU32 in);
ImU32 imgui_ColorConvertFloat4ToU32(const ImVec4& in);
void imgui_ColorConvertRGBtoHSV(float r, float g, float b, float& out_h, float& out_s, float& out_v);
void imgui_ColorConvertHSVtoRGB(float h, float s, float v, ImVec4 &back);
// Inputs
int imgui_GetKeyIndex(ImGuiContext& g, ImGuiKey imgui_key);
bool imgui_IsKeyDown(ImGuiContext& g, int user_key_index);
bool imgui_IsKeyPressed(ImGuiContext& g, int user_key_index, bool repeat);
bool imgui_IsKeyReleased(ImGuiContext& g, int user_key_index);
int imgui_GetKeyPressedAmount(ImGuiContext& g, int key_index, float repeat_delay, float rate);
bool imgui_IsMouseDown(ImGuiContext& g, int button);
bool imgui_IsAnyMouseDown(ImGuiContext& g);
bool imgui_IsMouseClicked(ImGuiContext& g, int button, bool repeat);
bool imgui_IsMouseDoubleClicked(ImGuiContext& g, int button);
bool imgui_IsMouseReleased(ImGuiContext& g, int button);
bool imgui_IsMouseDragging(ImGuiContext& g, int button, float lock_threshold);
bool imgui_IsMouseHoveringRect(ImGuiContext& g, const ImVec2& r_min, const ImVec2& r_max, bool clip);
bool imgui_IsMousePosValid(ImGuiContext& g, const ImVec2* mouse_pos);
void imgui_GetMousePos(ImGuiContext& g, ImVec2* res);
void imgui_GetMousePosOnOpeningCurrentPopup(ImGuiContext& g, ImVec2* res);
void imgui_GetMouseDragDelta(ImGuiContext& g, ImVec2* res, int button, float lock_threshold);
void imgui_ResetMouseDragDelta(ImGuiContext& g, int button);
void imgui_GetMouseCursor(ImGuiContext& g, ImGuiMouseCursor* res);
void imgui_SetMouseCursor(ImGuiContext& g, ImGuiMouseCursor type);
void imgui_CaptureKeyboardFromApp(ImGuiContext& g, bool capture);
void imgui_CaptureMouseFromApp(ImGuiContext& g, bool capture);
// Clipboard Utilities
const char* imgui_GetClipboardText(ImGuiContext& g);
void imgui_SetClipboardText(ImGuiContext& g, const char* text);
// Settings/.Ini Utilities
void imgui_LoadIniSettingsFromDisk(ImGuiContext& g, const char* ini_filename);
void imgui_LoadIniSettingsFromMemory(ImGuiContext& g, const char* ini_data, size_t ini_size);
void imgui_SaveIniSettingsToDisk(ImGuiContext& g, const char* ini_filename);
const char* imgui_SaveIniSettingsToMemory(ImGuiContext& g, size_t* out_ini_size);
//
void imgui_Scrollbar(ImGuiContext& g, ImGuiLayoutType direction);
// Member functions
void imgui_ImDrawList_AddRect(ImDrawList *drawList, const ImVec2& a, const ImVec2& b, ImU32 col, float rounding, int rounding_corners_flags, float thickness);
void imgui_ImDrawList_AddRectFilled(ImDrawList *drawList, const ImVec2& a, const ImVec2& b, ImU32 col, float rounding, int rounding_corners_flags);
void imgui_ImDrawList_AddText1(ImDrawList *obj, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end);
void imgui_ImDrawList_AddText2(ImDrawList *obj, const ImFont* font, float font_size, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end, float wrap_width, const ImVec4* cpu_fine_clip_rect);
void imgui_ImDrawList_AddImage(ImDrawList *obj, ImTextureID user_texture_id, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, ImU32 col);
bool imgui_ImGuiTextFilter_Draw(ImGuiTextFilter *obj, ImGuiContext& g, const char* label, float width);
// Helper functions
bool imgui_GetImGuiIO_FontAllowUserScaling(ImGuiContext& g);
bool imgui_ImGuiIO_KeyCtrl(ImGuiContext& g);
float imgui_ImGuiIO_DeltaTime(ImGuiContext& g);
void imgui_ImGuiStyle_ItemSpacing(ImGuiContext& g, ImVec2* res);
void imgui_ImGuiStyle_ItemInnerSpacing(ImGuiContext& g, ImVec2* res);
int imgui_ImGuiIO_Fonts_TexWidth(ImGuiIO *imGuiIO);
int imgui_ImGuiIO_Fonts_TexHeight(ImGuiIO *imGuiIO);
void* imgui_ImGuiIO_Fonts_TexID(ImGuiIO *imGuiIO);
void imgui_ImGuiIO_MousePos(ImGuiIO *imGuiIO, ImVec2* res);
]]

local ctx = nil --ffi.new("ImGuiContext[1]")

--TYPES
local function Bool(x)
  return ffi.new("bool", x)
end
local function BoolPtr(x)
  return ffi.new("bool[1]", x)
end

local function CharPtr(x)
  return ffi.new("char[1]", x)
end

local function Int(x)
  return ffi.new("int", x)
end
local function IntPtr(x)
  return ffi.new("int[1]", x)
end

local function Float(x)
  return ffi.new("float", x)
end
local function FloatPtr(x)
  return ffi.new("float[1]", x)
end

local function Double(x)
  return ffi.new("double", x)
end
local function DoublePtr(x)
  return ffi.new("double[1]", x)
end

local function ArrayBoolByTbl(tbl)
  local arr = ffi.new("bool[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("bool", tbl[i+1])
  end
  return arr
end

local function ArrayBoolPtrByTbl(tbl)
  local arr = ffi.new("bool*[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("bool[1]", tbl[i+1])
  end
  return arr
end

local function ArrayIntPtrByTbl(tbl)
  local arr = ffi.new("int*[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("int[1]", tbl[i+1])
  end
  return arr
end

local function ArrayChar(x)
  return ffi.new("char[?]", x)
end

local function ArrayInt(size)
  return ffi.new("int[?]", size)
end

local function ArrayFloat(size)
  return ffi.new("float[?]", size)
end

local function ArrayFloatByTbl(tbl)
  local arr = ffi.new("float[?]", #tbl)
  for i = 0, #tbl - 1 do
    arr[i] = tbl[i+1]
  end
  return arr
end

local function ArrayImVec4(size)
  return ffi.new("ImVec4[?]", size)
end

local function ImVec2(x, y)
  local res = ffi.new("ImVec2")
  res.x = x
  res.y = y
  return res
end
local function ImVec2Ptr(x, y)
  local res = ffi.new("ImVec2[1]")
  res[0].x = x or 0
  res[0].y = y or 0
  return res
end

local function ImVec3(x, y, z)
  local res = ffi.new("ImVec3")
  res.x = x
  res.y = y
  res.z = z
  return res
end
local function ImVec3Ptr(x, y, z)
  local res = ffi.new("ImVec3[1]")
  res[0].x = x
  res[0].y = y
  res[0].z = z
  return res
end

local function ImVec4(x, y, z, w)
  local res = ffi.new("ImVec4")
  res.x = x
  res.y = y
  res.z = z
  res.w = w
  return res
end
local function ImVec4Ptr(x, y, z, w)
  local res = ffi.new("ImVec4[1]")
  res[0].x = x
  res[0].y = y
  res[0].z = z
  res[0].w = w
  return res
end

local function ImColorByRGB(r, g, b, a)
  local res = ffi.new("ImColor")
  local sc = 1/255
  res.Value = ImVec4(r * sc, g * sc, b * sc, a * sc or 1)
  return res
end

local BoolTrue = Bool(true)
local BoolFalse = Bool(false)
local IntZero = Int(0)
local IntOne = Int(1)
local IntNegOne = Int(-1)
local FloatZero = Float(0.0)
local FloatOne = Float(1.0)
local FloatNegOne = Float(-1.0)
local ImVec2Zero = ImVec2(0,0)
local ImVec2One = ImVec2(1,1)
local ImVec4Zero = ImVec4(0,0,0,0)
local ImVec4One = ImVec4(1,1,1,1)

-- ENUMS

--WIP
-- local function ImGuiColorEditFlags(x)
--   -- if type(x) == 'table'
--   -- return ffi.new("ImGuiColorEditFlags_", x)
--   return ffi.new("ImGuiColorEditFlags_", x)
-- end

-- local function enum(enumval, x)
--   return ffi.new(enumval, x)
-- end

-- local function enumWrapper(tag)
--   return function(values)
--     local res = 0
--     for _,v in ipairs(values) do
--       bit.bor(res, ffi.new(tag .. '_', tag .. '_' .. v))
--     end
--     return res
--   end
-- end

-- M.ImGuiColorEditFlags = enumWrapper('ImGuiColorEditFlags')


-- core_imgui.ImGuiColorEditFlags({'NoSidePreview', 'NoSmallPreview'})

f.ImGuiLayoutType = function(x)
  return ffi.new("ImGuiLayoutType_", x)
end
f.ImGuiWindowFlags = function(x)
  return ffi.new("ImGuiWindowFlags_", x)
end
f.ImGuiInputTextFlags = function(x)
  return ffi.new("ImGuiInputTextFlags_", x)
end
f.ImGuiComboFlags = function(x)
  return ffi.new("ImGuiComboFlags_", x)
end
f.ImGuiCol = function(x)
  return ffi.new("ImGuiCol_", x)
end
f.ImDrawCornerFlags = function(x)
  return ffi.new("ImDrawCornerFlags_", x)
end
f.ImGuiCond = function(x)
  return ffi.new("ImGuiCond_", x)
end
f.ImGuiSelectableFlags = function(x)
  return ffi.new("ImGuiSelectableFlags_", x)
end
f.ImGuiTreeNodeFlags = function(x)
  return ffi.new("ImGuiTreeNodeFlags_", x)
end
f.ImGuiHoveredFlags = function(x)
  return ffi.new("ImGuiHoveredFlags_", x)
end
f.ImGuiColorEditFlags = function(x)
  return ffi.new("ImGuiColorEditFlags_", x)
end
f.ImGuiKey = function(x)
  return ffi.new("ImGuiKey_", x)
end
f.ImGuiDataType = function(x)
  return ffi.new("ImGuiDataType_", x)
end
f.ImGuiDir = function(x)
  return ffi.new("ImGuiDir_", x)
end
f.ImGuiStyleVar = function(x)
  return ffi.new("ImGuiStyleVar_", x)
end
f.ImGuiColumnsFlags = function(x)
  return ffi.new("ImGuiColumnsFlags_", x)
end
f.ImGuiDragDropFlags = function(x)
  return ffi.new("ImGuiDragDropFlags_", x)
end
f.ImFontAtlasFlags = function(x)
  return ffi.new("ImFontAtlasFlags_", x)
end
f.ImDrawListFlags = function(x)
  return ffi.new("ImDrawListFlags_", x)
end
f.ImGuiConfigFlags = function(x)
  return ffi.new("ImGuiConfigFlags_", x)
end
f.ImGuiBackendFlags = function(x)
  return ffi.new("ImGuiBackendFlags_", x)
end
f.ImGuiNavInput = function(x)
  return ffi.new("ImGuiNavInput_", x)
end
f.ImGuiFocusedFlags = function(x)
  return ffi.new("ImGuiFocusedFlags_", x)
end

-- HELPER
f.ArraySize = function(arr)
  return ffi.sizeof(arr) / ffi.sizeof(arr[0])
end

f.GetLengthArrayBool = function(array)
  return ffi.sizeof(array) / ffi.sizeof("bool")
end

f.GetLengthArrayFloat = function(array)
  return ffi.sizeof(array) / ffi.sizeof("float")
end

f.GetLengthArrayInt = function(array)
  return ffi.sizeof(array) / ffi.sizeof("int")
end

f.GetLengthArrayCharPtr = function(array)
  return (ffi.sizeof(array) / ffi.sizeof("char*")) - 1
end

f.GetLengthArrayImVec4 = function(array)
  return ffi.sizeof(array) / ffi.sizeof("ImVec4")
end

f.ArrayCharPtrByTbl = function(tbl)
  local arr = ffi.new("const char*[".. #tbl + 1 .."]", tbl)
  return arr
end

-- WRAPPER
-- Context creation and access
-- Main
f.CreateIO = function()
  return ffi.C.imgui_CreateIO(ctx)
end
f.GetIO = function(p_open)
  ffi.C.imgui_GetIO(ctx, p_open or nil)
end
f.GetStyle = function(p_open)
  ffi.C.imgui_GetStyle(ctx, p_open or nil)
end

-- Demo, Debug, Information
f.ShowDemoWindow = function(p_open)
  ffi.C.imgui_ShowDemoWindow(ctx, p_open or nil)
end
f.ShowMetricsWindow = function(p_open)
  ffi.C.imgui_ShowMetricsWindow(ctx, p_open or nil)
end
f.ShowStyleEditor = function(ref)
  ffi.C.imgui_ShowStyleEditor(ctx, ref or nil)
end
f.ShowStyleSelector = function(label)
  return ffi.C.imgui_ShowStyleSelector(ctx, label)
end
f.ShowFontSelector = function(label)
  ffi.C.imgui_ShowFontSelector(ctx, label)
end
f.ShowUserGuide = function()
  ffi.C.imgui_ShowUserGuide(ctx)
end
f.GetVersion = function()
  return ffi.C.imgui_GetVersion()
end

-- Style
f.StyleColorsDark = function(dst)
  ffi.C.imgui_StyleColorsDark(ctx, dst)
end
f.StyleColorsClassic = function(dst)
  ffi.C.imgui_StyleColorsClassic(ctx, dst)
end
f.StyleColorsLight = function(dst)
  ffi.C.imgui_StyleColorsLight(ctx, dst)
end

-- Windows
f.Begin = function(name, p_open, flags)
  return ffi.C.imgui_Begin(ctx, name, p_open, flags or f.ImGuiWindowFlags("ImGuiWindowFlags_NoTitleBar"))
end
f.End = function()
  return ffi.C.imgui_End(ctx)
end
f.BeginChild1 = function(str_id, size, border, flags)
  return ffi.C.imgui_BeginChild1(ctx, str_id, size or ImVec2Zero, border or BoolFalse, flags or f.ImGuiWindowFlags("ImGuiWindowFlags_NoTitleBar"))
end
f.BeginChild2 = function(id, size, border, flags)
  return ffi.C.imgui_BeginChild2(ctx, id, size or ImVec2Zero, border or BoolFalse, flags or IntZero)
end
f.EndChild = function()
  ffi.C.imgui_EndChild(ctx)
end

-- Windows: Utilities
f.IsWindowAppearing = function()
  return ffi.C.imgui_IsWindowAppearing(ctx)
end
f.IsWindowCollapsed = function()
  return ffi.C.imgui_IsWindowCollapsed(ctx)
end
f.IsWindowFocused = function(flags)
  return ffi.C.imgui_IsWindowFocused(ctx, flags or IntZero)
end
f.IsWindowHovered = function(flags)
  return ffi.C.imgui_IsWindowHovered(ctx, flags or IntZero)
end
f.GetWindowDrawList = function()
  return ffi.C.imgui_GetWindowDrawList(ctx)
end
f.GetWindowPos = function(res)
  ffi.C.imgui_GetWindowPos(ctx, res)
end
f.GetWindowSize = function(res)
  ffi.C.imgui_GetWindowSize(ctx, res)
end
f.GetWindowWidth = function()
  return ffi.C.imgui_GetWindowWidth(ctx)
end
f.GetWindowHeight = function()
  return ffi.C.imgui_GetWindowHeight(ctx)
end
f.GetContentRegionMax = function(res)
  ffi.C.imgui_GetContentRegionMax(ctx, res)
end
f.GetContentRegionAvail = function(res)
  ffi.C.imgui_GetContentRegionAvail(ctx, res)
end
f.GetContentRegionAvailWidth = function()
  return ffi.C.imgui_GetContentRegionAvailWidth(ctx)
end
f.GetWindowContentRegionMin = function(res)
  ffi.C.imgui_GetWindowContentRegionMin(ctx, res)
end
f.GetWindowContentRegionMax = function()
  ffi.C.imgui_GetWindowContentRegionMax(ctx, res)
end
f.GetWindowContentRegionWidth = function()
  return ffi.C.imgui_GetWindowContentRegionWidth(ctx)
end

f.SetNextWindowPos = function(pos, cond, pivot)
  ffi.C.imgui_SetNextWindowPos(ctx, pos, cond or IntZero, pivot or ImVec2Zero)
end
f.SetNextWindowSize = function(pos, cond)
  ffi.C.imgui_SetNextWindowSize(ctx, pos, cond or IntZero)
end
f.SetNextWindowSizeConstraints = function(size_min, size_max, custom_callback, custom_callback_data)
  ffi.C.imgui_SetNextWindowSizeConstraints(ctx, size_min, size_max, custom_callback or nil, custom_callback_data or nil)
end
f.SetNextWindowContentSize = function(size)
  ffi.C.imgui_SetNextWindowContentSize(ctx, size)
end

f.SetNextWindowCollapsed = function(collapsed, cond)
  ffi.C.imgui_SetNextWindowCollapsed(ctx, collapsed, cond or IntZero)
end
f.SetNextWindowFocus = function()
  ffi.C.imgui_SetNextWindowFocus(ctx)
end
f.SetNextWindowBgAlpha = function(alpha)
  ffi.C.imgui_SetNextWindowBgAlpha(ctx, alpha)
end
f.SetWindowPos1 = function(pos, cond)
  ffi.C.imgui_SetWindowPos1(ctx, pos, cond or IntZero)
end
f.SetWindowSize1 = function(size, cond)
  ffi.C.imgui_SetWindowSize1(ctx, size, cond or IntZero)
end
f.SetWindowCollapsed1 = function(collapsed, cond)
  ffi.C.imgui_SetWindowCollapsed1(ctx, collapsed, cond or IntZero)
end
f.SetWindowFocus1 = function()
  ffi.C.imgui_SetWindowFocus1(ctx)
end
f.SetWindowFontScale = function(scale)
  ffi.C.imgui_SetWindowFontScale(ctx, scale)
end
f.SetWindowPos2 = function(name, pos, cond)
  ffi.C.imgui_SetWindowPos2(ctx, name, pos, cond or IntZero)
end
f.SetWindowSize2 = function(name, size, cond)
  ffi.C.imgui_SetWindowSize2(ctx, name, size, cond or IntZero)
end
f.SetWindowCollapsed2 = function(name, collapsed, cond)
  ffi.C.imgui_SetWindowCollapsed2(ctx, name, collapsed, cond or IntZero)
end
f.SetWindowFocus2 = function(name)
  ffi.C.imgui_SetWindowFocus2(ctx, name)
end

-- Windows Scrolling
f.GetScrollX = function()
  return ffi.C.imgui_GetScrollX(ctx)
end
f.GetScrollY = function()
  return ffi.C.imgui_GetScrollY(ctx)
end
f.GetScrollMaxX = function()
  return ffi.C.imgui_GetScrollMaxX(ctx)
end
f.GetScrollMaxY = function()
  return ffi.C.imgui_GetScrollMaxY(ctx)
end
f.SetScrollX = function(scroll_x)
  ffi.C.imgui_SetScrollX(ctx, scroll_x)
end
f.SetScrollY = function(scroll_y)
  ffi.C.imgui_SetScrollY(ctx, scroll_y)
end
f.SetScrollHere = function(center_y_ratio)
  ffi.C.imgui_SetScrollHere(ctx, center_y_ratio or Float(0.5))
end
f.SetScrollFromPosY = function(pos_y, center_y_ratio)
  ffi.C.imgui_SetScrollFromPosY(ctx, pos_y, center_y_ratio or Float(0.5))
end

-- Parameters stacks (shared)
f.PushFont = function(font)
  ffi.C.imgui_PushFont(ctx, font)
end
f.PopFont = function()
  ffi.C.imgui_PopFont(ctx)
end
f.PushStyleColor1 = function(idx, col)
  ffi.C.imgui_PushStyleColor1(ctx, idx, col)
end
f.PushStyleColor2 = function(idx, col)
  ffi.C.imgui_PushStyleColor2(ctx, idx, col)
end
f.PopStyleColor = function(count)
  ffi.C.imgui_PopStyleColor(ctx, count or IntOne)
end
f.PushStyleVar1 = function(idx, val)
  ffi.C.imgui_PushStyleVar1(ctx, idx, val)
end
f.PushStyleVar2 = function(idx, val)
  ffi.C.imgui_PushStyleVar2(ctx, idx, val)
end
f.PopStyleVar = function(count)
  ffi.C.imgui_PopStyleVar(ctx, count or IntOne)
end
f.GetStyleColorVec4 = function(idx)
  return ffi.C.imgui_GetStyleColorVec4(ctx, idx)
end
f.GetFont = function()
  return ffi.C.imgui_GetFont(ctx)
end
f.GetFontSize = function()
  return ffi.C.imgui_GetFontSize(ctx)
end
f.GetFontTexUvWhitePixel = function(res)
  ffi.C.imgui_GetFontTexUvWhitePixel(ctx, res)
end
f.GetColorU321 = function(idx, alpha_mul)
  return ffi.C.imgui_GetColorU321(ctx, idx, alpha_mul or FloatOne)
end
f.GetColorU322 = function(col)
  return ffi.C.imgui_GetColorU322(ctx, col)
end
f.GetColorU323 = function(col)
  return ffi.C.imgui_GetColorU323(ctx, col)
end

-- Parameters stacks (current window)
f.PushItemWidth = function(item_width)
  ffi.C.imgui_PushItemWidth(ctx, item_width)
end
f.PopItemWidth = function()
  ffi.C.imgui_PopItemWidth(ctx)
end
f.CalcItemWidth = function()
  return ffi.C.imgui_CalcItemWidth(ctx)
end
f.PushTextWrapPos = function(wrap_pos_x)
  ffi.C.imgui_PushTextWrapPos(ctx, wrap_pos_x or FloatZero)
end
f.PopTextWrapPos = function()
  ffi.C.imgui_PopTextWrapPos(ctx)
end
f.PushAllowKeyboardFocus = function(allow_keyboard_focus)
  ffi.C.imgui_PushAllowKeyboardFocus(ctx, allow_keyboard_focus)
end
f.PopAllowKeyboardFocus = function()
  ffi.C.imgui_PopAllowKeyboardFocus(ctx)
end
f.PushButtonRepeat = function(repeated)
  ffi.C.imgui_PushButtonRepeat(ctx, repeated)
end
f.PopButtonRepeat = function()
  ffi.C.imgui_PopButtonRepeat(ctx)
end

-- Cursor / Layout
f.Separator = function()
  ffi.C.imgui_Separator(ctx)
end
f.SameLine = function(pos_x, spacing_w)
  ffi.C.imgui_SameLine(ctx, pos_x or FloatZero, spacing_w or FloatNegOne)
end
f.NewLine = function()
  ffi.C.imgui_NewLine(ctx)
end
f.Spacing = function()
  ffi.C.imgui_Spacing(ctx)
end
f.Dummy = function(size)
  ffi.C.imgui_Dummy(ctx, size)
end
f.Indent = function(indent_w)
  ffi.C.imgui_Indent(ctx, indent_w or FloatZero)
end
f.Unindent = function(indent_w)
  ffi.C.imgui_Unindent(ctx, indent_w or FloatZero)
end
f.BeginGroup = function()
  ffi.C.imgui_BeginGroup(ctx)
end
f.EndGroup = function()
  ffi.C.imgui_EndGroup(ctx)
end
f.GetCursorPos = function(res)
  ffi.C.imgui_GetCursorPos(ctx, res)
end
f.GetCursorPosX = function()
  return ffi.C.imgui_GetCursorPosX(ctx)
end
f.GetCursorPosY = function()
  return ffi.C.imgui_GetCursorPosY(ctx)
end
f.SetCursorPos = function(local_pos)
  ffi.C.imgui_SetCursorPos(ctx, local_pos)
end
f.SetCursorPosX = function(x)
  ffi.C.imgui_SetCursorPosX(ctx, x)
end
f.SetCursorPosY = function(y)
  ffi.C.imgui_SetCursorPosY(ctx, y)
end
f.GetCursorStartPos = function(res)
  ffi.C.imgui_GetCursorStartPos(ctx, res)
end
f.GetCursorScreenPos = function(res)
  ffi.C.imgui_GetCursorScreenPos(ctx, res)
end
f.SetCursorScreenPos = function(screen_pos)
  return ffi.C.imgui_SetCursorScreenPos(ctx, screen_pos)
end
f.AlignTextToFramePadding = function()
  return ffi.C.imgui_AlignTextToFramePadding(ctx)
end
f.GetTextLineHeight = function()
  return ffi.C.imgui_GetTextLineHeight(ctx)
end
f.GetTextLineHeightWithSpacing = function()
  return ffi.C.imgui_GetTextLineHeightWithSpacing(ctx)
end
f.GetFrameHeight = function()
  return ffi.C.imgui_GetFrameHeight(ctx)
end
f.GetFrameHeightWithSpacing = function()
  return ffi.C.imgui_GetFrameHeightWithSpacing(ctx)
end

-- ID stack/scopes
f.PushID1 = function(str_id)
  return ffi.C.imgui_PushID1(ctx, str_id)
end
f.PushID2 = function(str_id_begin, str_id_end)
  return ffi.C.imgui_PushID2(ctx, str_id_begin, str_id_end)
end
f.PushID3 = function(ptr_id)
  return ffi.C.imgui_PushID3(ctx, ptr_id)
end
f.PushID4 = function(int_id)
  return ffi.C.imgui_PushID4(ctx, int_id)
end
f.PopID = function()
  return ffi.C.imgui_PopID(ctx)
end
f.GetID1 = function(str_id)
  return ffi.C.imgui_GetID1(ctx, str_id)
end
f.GetID2 = function(str_id_begin, str_id_end)
  return ffi.C.imgui_GetID2(ctx, str_id_begin, str_id_end)
end
f.GetID3 = function(ptr_id)
  return ffi.C.imgui_GetID3(ctx, ptr_id)
end

-- Widgets: Text
f.TextUnformatted = function(text, text_end)
  ffi.C.imgui_TextUnformatted(ctx, text, text_end or nil)
end
f.Text = function(fmt, ...)
  ffi.C.imgui_Text(ctx, fmt, ...)
end
f.TextColored = function(col, fmt, ...)
  ffi.C.imgui_TextColored(ctx, col, fmt, ...)
end
f.TextDisabled = function(fmt, ...)
  ffi.C.imgui_TextDisabled(ctx, fmt, ...)
end
f.TextWrapped = function(fmt, ...)
  ffi.C.imgui_TextWrapped(ctx, fmt, ...)
end
f.LabelText = function(label, fmt, ...)
  ffi.C.imgui_LabelText(ctx, label, fmt, ...)
end
f.BulletText = function(fmt, ...)
  ffi.C.imgui_BulletText(ctx, fmt, ...)
end

-- Widgets: Main
f.Button = function(label, size)
  return ffi.C.imgui_Button(ctx, label, size or ImVec2Zero)
end
f.SmallButton = function(label)
  return ffi.C.imgui_SmallButton(ctx, label)
end
f.ArrowButton = function(str_id, dir)
  return ffi.C.imgui_ArrowButton(ctx, str_id, dir)
end
f.InvisibleButton = function(str_id, size)
  return ffi.C.imgui_InvisibleButton(ctx, str_id, size)
end
f.Image = function(user_texture_id, size, uv0, uv1, tint_col, border_col)
  ffi.C.imgui_Image(ctx, user_texture_id, size, uv0 or ImVec2Zero, uv1 or ImVec2One, tint_col or ImVec4One, border_col or ImVec4Zero)
end
f.ImageButton = function(user_texture_id, size, uv0, uv1, frame_padding, bg_col, tint_col)
  return ffi.C.imgui_ImageButton(ctx, user_texture_id, size, uv0 or ImVec2Zero, uv1 or ImVec2One, frame_padding or IntNegOne, bg_col or ImVec4Zero, tint_col or ImVec4One)
end
f.Checkbox = function(label, v)
  return ffi.C.imgui_Checkbox(ctx, label, v)
end
f.CheckboxFlags = function(label, flags, flags_value)
  return ffi.C.imgui_CheckboxFlags(ctx, label, flags, flags_value)
end
f.RadioButton1 = function(label, active)
  return ffi.C.imgui_RadioButton1(ctx, label, active)
end
f.RadioButton2 = function(label, v, v_button)
  return ffi.C.imgui_RadioButton2(ctx, label, v, v_button)
end
f.PlotLines1 = function(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
  ffi.C.imgui_PlotLines1(ctx, label, values, values_count, values_offset or IntZero, overlay_text or nil, scale_min or FLT_MAX, scale_max or FLT_MAX, graph_size or ImVec2Zero)
end
f.PlotLines2 = function(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
  ffi.C.imgui_PlotLines2(ctx, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
end
f.PlotHistogram1 = function(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
  ffi.C.imgui_PlotHistogram1(ctx, label, values, values_count, values_offset or IntZero, overlay_text or nil, scale_min or FLT_MAX, scale_max or FLT_MAX, graph_size or ImVec2Zero)
end
f.PlotHistogram2 = function(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
  ffi.C.imgui_PlotHistogram2(ctx, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
end
f.ProgressBar = function(fraction, size_arg, overlay)
  ffi.C.imgui_ProgressBar(ctx, fraction, size_arg or ImVec2(-1.0, 0.0), overlay or nil)
end
f.Bullet = function()
  ffi.C.imgui_Bullet(ctx)
end

-- Widgets: Combo Box
f.BeginCombo = function(label, preview_value, flags)
  return ffi.C.imgui_BeginCombo(ctx, label, preview_value, flags or IntZero)
end
f.EndCombo = function()
  return ffi.C.imgui_EndCombo(ctx)
end
f.Combo1 = function(label, current_item, items, items_count, popup_max_height_in_items)
  return ffi.C.imgui_Combo1(ctx, label, current_item, items, items_count or f.GetLengthArrayCharPtr(items), popup_max_height_in_items or IntNegOne)
end
f.Combo2 = function(label, current_item, items_separated_by_zeros, popup_max_height_in_items)
  return ffi.C.imgui_Combo2(ctx, label, current_item, items_separated_by_zeros, popup_max_height_in_items or IntNegOne)
end

-- Widgets: Drags
f.DragFloat = function(label, v, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragFloat(ctx, label, v, v_speed or FloatOne, v_min or FloatZero, v_max or FloatZero, format or "%.3f", power or FloatOne)
end
f.DragFloat2 = function(label, v, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragFloat2(ctx, label, v, v_speed or FloatOne, v_min or FloatZero, v_max or FloatZero, format or "%.3f", power or FloatOne)
end
f.DragFloat3 = function(label, v, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragFloat3(ctx, label, v, v_speed or FloatOne, v_min or FloatZero, v_max or FloatZero, format or "%.3f", power or FloatOne)
end
f.DragFloat4 = function(label, v, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragFloat4(ctx, label, v, v_speed or FloatOne, v_min or FloatZero, v_max or FloatZero, format or "%.3f", power or FloatOne)
end
f.DragFloatRange2 = function(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max, power)
  return ffi.C.imgui_DragFloatRange2(ctx, label, v_current_min, v_current_max, v_speed or FloatOne, v_min or FloatZero, v_max or FloatZero, format or "%.3f", format_max or nil, power or FloatOne)
end
f.DragInt = function(label, v, v_speed, v_min, v_max, format)
  return ffi.C.imgui_DragInt(ctx, label, v, v_speed or FloatOne, v_min or IntZero, v_max or IntZero, format or "%d")
end
f.DragInt2 = function(label, v, v_speed, v_min, v_max, format)
  return ffi.C.imgui_DragInt2(ctx, label, v, v_speed or FloatOne, v_min or IntZero, v_max or IntZero, format or "%d")
end
f.DragInt3 = function(label, v, v_speed, v_min, v_max, format)
  return ffi.C.imgui_DragInt3(ctx, label, v, v_speed or FloatOne, v_min or IntZero, v_max or IntZero, format or "%d")
end
f.DragInt4 = function(label, v, v_speed, v_min, v_max, format)
  return ffi.C.imgui_DragInt4(ctx, label, v, v_speed or FloatOne, v_min or IntZero, v_max or IntZero, format or "%d")
end
f.DragIntRange2 = function(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max)
  return ffi.C.imgui_DragIntRange2(ctx, label, v_current_min, v_current_max, v_speed or FloatOne, v_min or IntZero, v_max or IntZero, format or "%d", format_max or nil)
end
f.DragScalar = function(label, data_type, v, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragScalar(ctx, label, data_type, v, v_speed, v_min or nil, v_max or nil, format or nil, power or FloatOne)
end
f.DragScalarN = function(label, data_type, v, components, v_speed, v_min, v_max, format, power)
  return ffi.C.imgui_DragScalarN(ctx, label, data_type, v, components, v_speed, v_min or nil, v_max or nil, format or nil, power or FloatOne)
end

-- Widgets: Input with Keyboard
f.InputText = function(label, buf, buf_size, flags, callback, user_data)
  return ffi.C.imgui_InputText(ctx, label, buf, buf_size or ffi.sizeof(buf), flags or IntZero, callback or nil, user_data or nil )
end
f.InputTextMultiline = function(label, buf, buf_size, size, flags, callback, user_data)
  return ffi.C.imgui_InputTextMultiline(ctx, label, buf, buf_size or ffi.sizeof(buf), size or ImVec2Zero, flags or IntZero, callback or nil, user_data or nil)
end
f.InputTextMultilineReadOnly = function(label, buf, size, flags, callback, user_data)
  return ffi.C.imgui_InputTextMultilineReadOnly(ctx, label, buf, size or ImVec2Zero, flags or IntZero, callback or nil, user_data or nil)
end
f.InputFloat = function(label, v, step, step_fast, format, extra_flags)
  return ffi.C.imgui_InputFloat(ctx, label, v, step or FloatZero, step_fast or FloatZero, format or "%.3f", extra_flags or IntZero)
end
f.InputFloat2 = function(label, v, format, extra_flags)
  return ffi.C.imgui_InputFloat2(ctx, label, v, format or "%.3f", extra_flags or IntZero)
end
f.InputFloat3 = function(label, v, format, extra_flags)
  return ffi.C.imgui_InputFloat3(ctx, label, v, format or "%.3f", extra_flags or IntZero)
end
f.InputFloat4 = function(label, v, format, extra_flags)
  return ffi.C.imgui_InputFloat4(ctx, label, v, format or "%.3f", extra_flags or IntZero)
end
f.InputInt = function(label, v, step, step_fast, extra_flags)
  return ffi.C.imgui_InputInt(ctx, label, v, step or IntOne, step_fast or Int(100), extra_flags or IntZero)
end
f.InputInt2 = function(label, v, extra_flags)
  return ffi.C.imgui_InputInt2(ctx, label, v, extra_flags or IntZero)
end
f.InputInt3 = function(label, v, extra_flags)
  return ffi.C.imgui_InputInt3(ctx, label, v, extra_flags or IntZero)
end
f.InputInt4 = function(label, v, extra_flags)
  return ffi.C.imgui_InputInt4(ctx, label, v, extra_flags or IntZero)
end
f.InputDouble = function(label, v, step, step_fast, format, extra_flags)
  return ffi.C.imgui_InputDouble(ctx, label, v, step or FloatZero, step_fast or FloatZero, format or "%.6f", extra_flags or IntZero)
end
f.InputScalar = function(label, data_type, v, step, step_fast, format, extra_flags)
  return ffi.C.imgui_InputScalar(ctx, label, data_type, v, step or nil, step_fast or nil, format or nil, extra_flags or IntZero)
end
f.InputScalarN = function(label, data_type, v, components, step, step_fast, format, extra_flags)
  return ffi.C.imgui_InputScalarN(ctx, label, data_type, v, components, step or nil, step_fast or nil, format or nil, extra_flags or IntZero)
end

-- Widgets: Sliders
f.SliderFloat = function(label, v, v_min, v_max, format, power)
  return ffi.C.imgui_SliderFloat(ctx, label, v, v_min, v_max, format or "%.3f", power or FloatOne)
end
f.SliderFloat2 = function(label, v, v_min, v_max, format, power)
  return ffi.C.imgui_SliderFloat2(ctx, label, v, v_min, v_max, format or "%.3f", power or FloatOne)
end
f.SliderFloat3 = function(label, v, v_min, v_max, format, power)
  return ffi.C.imgui_SliderFloat3(ctx, label, v, v_min, v_max, format or "%.3f", power or FloatOne)
end
f.SliderFloat4 = function(label, v, v_min, v_max, format, power)
  return ffi.C.imgui_SliderFloat4(ctx, label, v, v_min, v_max, format or "%.3f", power or FloatOne)
end
f.SliderAngle = function(label, v_rad, v_degrees_min, v_degrees_max)
  return ffi.C.imgui_SliderAngle(ctx, label, v_rad, v_degrees_min or Float(-360.0), v_degrees_max or Float(360.0))
end
f.SliderInt = function(label, v, v_min, v_max, format)
  return ffi.C.imgui_SliderInt(ctx, label, v, v_min, v_max, format or "%d")
end
f.SliderInt2 = function(label, v, v_min, v_max, format)
  return ffi.C.imgui_SliderInt2(ctx, label, v, v_min, v_max, format or "%d")
end
f.SliderInt3 = function(label, v, v_min, v_max, format)
  return ffi.C.imgui_SliderInt3(ctx, label, v, v_min, v_max, format or "%d")
end
f.SliderInt4 = function(label, v, v_min, v_max, format)
  return ffi.C.imgui_SliderInt4(ctx, label, v, v_min, v_max, format or "%d")
end
f.SliderScalar = function(label, data_type, v, v_min, v_max, format, power)
  return ffi.C.imgui_SliderScalar(ctx, label, data_type, v, v_min, v_max, format or nil, power or FloatOne)
end
f.SliderScalarN = function(label, data_type, v, components, v_min, v_max, format, power)
  return ffi.C.imgui_SliderScalarN(ctx, label, data_type, v, components, v_min, v_max, format or nil, power or FloatOne)
end
f.VSliderFloat = function(label, size, v, v_min, v_max, format, power)
  return ffi.C.imgui_VSliderFloat(ctx, label, size, v, v_min, v_max, format or "%.3f", power or FloatOne)
end
f.VSliderInt = function(label, size, v, v_min, v_max, format)
  return ffi.C.imgui_VSliderInt(ctx, label, size, v, v_min, v_max, format or "%d")
end
f.VSliderScalar = function(label, size, data_type, v, v_min, v_max, format, power)
  return ffi.C.imgui_VSliderScalar(ctx, label, size, data_type, v, v_min, v_max, format or nil, power or FloatOne)
end

-- Widgets: Color Editor/Picker
f.ColorEdit3 = function(label, col, flags)
  return ffi.C.imgui_ColorEdit3(ctx, label, col, flags or IntZero)
end
f.ColorEdit4 = function(label, col, flags)
  return ffi.C.imgui_ColorEdit4(ctx, label, col, flags or IntZero)
end
f.ColorPicker3 = function(label, col, flags)
  return ffi.C.imgui_ColorPicker3(ctx, label, col, flags or IntZero)
end
f.ColorPicker4 = function(label, col, flags, ref_col)
  return ffi.C.imgui_ColorPicker4(ctx, label, col, flags or IntZero, ref_col or nil)
end
f.ColorButton = function(desc_id, col, flags, size)
  return ffi.C.imgui_ColorButton(ctx, desc_id, col, flags or IntZero, size or ImVec2Zero)
end
f.SetColorEditOptions = function(flags)
  ffi.C.imgui_SetColorEditOptions(ctx, flags)
end

-- Widgets: Trees
f.TreeNode1 = function(label)
  return ffi.C.imgui_TreeNode1(ctx, label)
end
f.TreeNode2 = function(str_id, fmt, ...)
  return ffi.C.imgui_TreeNode2(ctx, str_id, fmt, ...)
end
f.TreeNode3 = function(ptr_id, fmt, ...)
  return ffi.C.imgui_TreeNode3(ctx, ptr_id, fmt, ...)
end
f.TreeNodeV1 = function(str_id, fmt, ...)
  return ffi.C.imgui_TreeNodeV1(ctx, str_id, fmt, ...)
end
f.TreeNodeV2 = function(ptr_id, fmt, ...)
  return ffi.C.imgui_TreeNodeV2(ctx, ptr_id, fmt, ...)
end
f.TreeNodeEx1 = function(label, flags)
  return ffi.C.imgui_TreeNodeEx1(ctx, label, flags or IntZero)
end
f.TreeNodeEx2 = function(str_id, flags, fmt, ...)
  return ffi.C.imgui_TreeNodeEx2(ctx, str_id, flags, fmt, ...)
end
f.TreeNodeEx3 = function(ptr_id, flags, fmt, ...)
  return ffi.C.imgui_TreeNodeEx3(ctx, ptr_id, flags, fmt, ...)
end
f.TreeNodeExV1 = function(str_id, flags, fmt, ...)
  return ffi.C.imgui_TreeNodeExV1(ctx, str_id, flags, fmt, ...)
end
f.TreeNodeExV2 = function(ptr_id, flags, fmt, ...)
  return ffi.C.imgui_TreeNodeExV2(ctx, ptr_id, flags, fmt, ...)
end
f.TreePush1 = function(str_id)
  ffi.C.imgui_TreePush1(ctx, str_id)
end
f.TreePush2 = function(ptr_id)
  ffi.C.imgui_TreePush2(ctx, ptr_id or nil)
end
f.TreePop = function()
  ffi.C.imgui_TreePop(ctx)
end
f.TreeAdvanceToLabelPos = function()
  ffi.C.imgui_TreeAdvanceToLabelPos(ctx)
end
f.GetTreeNodeToLabelSpacing = function()
  return ffi.C.GetTreeNodeToLabelSpacing(ctx)
end
f.SetNextTreeNodeOpen = function(is_open, cond)
  ffi.C.imgui_SetNextTreeNodeOpen(ctx, is_open, cond)
end
f.CollapsingHeader1 = function(label, flags)
  return ffi.C.imgui_CollapsingHeader1(ctx, label, flags or IntZero)
end
f.CollapsingHeader2 = function(label, p_open, flags)
  return ffi.C.imgui_CollapsingHeader2(ctx, label, p_open, flags or IntZero)
end

-- Widgets: Selectable / Lists
f.Selectable1 = function(label, selected, flags, size)
  return ffi.C.imgui_Selectable1(ctx, label, selected or BoolFalse, flags or IntZero, size or ImVec2Zero)
end
f.Selectable2 = function(label, p_selected, flags, size)
  return ffi.C.imgui_Selectable2(ctx, label, p_selected, flags or IntZero, size or ImVec2Zero)
end
f.ListBox = function(label, current_item, items, items_count, height_in_items)
  return ffi.C.imgui_ListBox(ctx, label, current_item, items, items_count or f.GetLengthArrayInt(items) - 1, height_in_items or IntNegOne)
end
f.ListBoxHeader1 = function(label, size)
  return ffi.C.imgui_ListBoxHeader1(ctx, label, size or ImVec2Zero)
end
f.ListBoxHeader2 = function(label, items_count, height_in_items)
  return ffi.C.imgui_ListBoxHeader2(ctx, label, items_count, height_in_items or IntNegOne)
end
f.ListBoxFooter = function()
  return ffi.C.imgui_ListBoxFooter(ctx)
end

-- Widgets: Value() Helpers
f.Value1 = function(prefix, b)
  ffi.C.imgui_imgui_Value1(ctx, prefix, b)
end
f.Value2 = function(prefix, v)
  ffi.C.imgui_imgui_Value2(ctx, prefix, v)
end
f.Value3 = function(prefix, v)
  ffi.C.imgui_imgui_Value3(ctx, prefix, v)
end
f.Value4 = function(prefix, v, float_format)
  ffi.C.imgui_imgui_Value4(ctx, prefix, v, float_format or nil)
end

-- Tooltips
f.SetTooltip = function(fmt, ...)
  ffi.C.imgui_SetTooltip(ctx, fmt, ...)
end
f.BeginTooltip = function()
  ffi.C.imgui_BeginTooltip(ctx)
end
f.EndTooltip = function()
  ffi.C.imgui_EndTooltip(ctx)
end

-- Menus
f.BeginMainMenuBar = function()
  return ffi.C.imgui_BeginMainMenuBar(ctx)
end
f.EndMainMenuBar = function()
  ffi.C.imgui_EndMainMenuBar(ctx)
end
f.BeginMenuBar = function()
  return ffi.C.imgui_BeginMenuBar(ctx)
end
f.EndMenuBar = function()
  ffi.C.imgui_EndMenuBar(ctx)
end
f.BeginMenu = function(label, enabled)
  return ffi.C.imgui_BeginMenu(ctx, label, enabled and BoolTrue or BoolFalse)
end
f.EndMenu = function()
  ffi.C.imgui_EndMenu(ctx)
end
f.MenuItem1 = function(label, shortcut, selected, enabled)
  return ffi.C.imgui_MenuItem1(ctx, label, shortcut or nil, selected or BoolFalse, enabled and BoolTrue or BoolFalse)
end
f.MenuItem2 = function(label, shortcut, p_selected, enabled)
  return ffi.C.imgui_MenuItem2(ctx, label, shortcut, p_selected, enabled and BoolTrue or BoolFalse)
end

-- Popups
f.OpenPopup = function(str_id)
  ffi.C.imgui_OpenPopup(ctx, str_id)
end
f.BeginPopup = function(str_id, flags)
  return ffi.C.imgui_BeginPopup(ctx, str_id, flags or IntZero)
end
f.BeginPopupContextItem = function(str_id, mouse_button)
  return ffi.C.imgui_BeginPopupContextItem(ctx, str_id or nil, mouse_button or IntOne)
end
f.BeginPopupContextWindow = function(str_id, mouse_button, also_over_items)
  return ffi.C.imgui_BeginPopupContextWindow(ctx, str_id or nil, mouse_button or IntOne, also_over_items and BoolTrue or BoolFalse)
end
f.BeginPopupContextVoid = function(str_id, mouse_button)
  return ffi.C.imgui_BeginPopupContextVoid(ctx, str_id or nil, mouse_button or IntOne)
end
f.BeginPopupModal = function(name, p_open, flags)
  return ffi.C.imgui_BeginPopupModal(ctx, name, p_open or nil, flags or IntZero)
end
f.EndPopup = function()
  ffi.C.imgui_EndPopup(ctx)
end
f.OpenPopupOnItemClick = function(str_id, mouse_button)
  return ffi.C.imgui_OpenPopupOnItemClick(ctx, str_id or nil, mouse_button or IntOne)
end
f.IsPopupOpen = function(str_id)
  return ffi.C.imgui_IsPopupOpen(ctx, str_id)
end
f.CloseCurrentPopup = function()
  ffi.C.imgui_CloseCurrentPopup(ctx)
end

-- Columns
f.Columns = function(count, id, border)
  ffi.C.imgui_Columns(ctx, count or IntOne, id or nil, border and BoolTrue or BoolFalse)
end
f.NextColumn = function()
  ffi.C.imgui_NextColumn(ctx)
end
f.GetColumnIndex = function()
  return ffi.C.imgui_GetColumnIndex(ctx)
end
f.GetColumnWidth = function(column_index)
  return ffi.C.imgui_GetColumnWidth(ctx, column_index or IntNegOne)
end
f.SetColumnWidth = function(column_index, width)
  ffi.C.imgui_SetColumnWidth(ctx, column_index, width)
end
f.GetColumnOffset = function(column_index)
  return ffi.C.imgui_GetColumnOffset(ctx, column_index or IntNegOne)
end
f.SetColumnOffset = function(column_index, offset_x)
  ffi.C.imgui_SetColumnOffset(ctx, column_index, offset_x)
end
f.GetColumnsCount = function()
  return ffi.C.imgui_GetColumnsCount(ctx)
end
f.BeginColumns = function(id, count, flags)
  ffi.C.imgui_BeginColumns(ctx, id or "", count or 2, flags or 0)
end
f.EndColumns = function()
  ffi.C.imgui_EndColumns(ctx)
end

-- Logging/Capture
f.LogToTTY = function(max_depth)
  ffi.C.imgui_LogToTTY(ctx, max_depth or IntNegOne)
end
f.LogToFile = function(max_depth, filename)
  ffi.C.imgui_LogToFile(ctx, max_depth or IntNegOne, filename or nil)
end
f.LogToClipboard = function(max_depth)
  ffi.C.imgui_LogToClipboard(ctx, max_depth or IntNegOne)
end
f.LogFinish = function()
  ffi.C.imgui_LogFinish(ctx)
end
f.LogButtons = function()
  ffi.C.imgui_LogButtons(ctx)
end
f.LogText = function(fmt, ...)
  ffi.C.imgui_LogText(ctx, fmt, ...)
end

-- Drag and Drop
f.BeginDragDropSource = function(flags)
  return ffi.C.imgui_BeginDragDropSource(ctx, flags or 0)
end
f.SetDragDropPayload = function(type, data, size, cond)
  return ffi.C.imgui_SetDragDropPayload(ctx, type, data, size, cond or 0)
end
f.EndDragDropSource = function()
  ffi.C.imgui_EndDragDropSource(ctx)
end
f.BeginDragDropTarget = function()
  return ffi.C.imgui_BeginDragDropTarget(ctx)
end
f.AcceptDragDropPayload = function(type, flags)
  return ffi.C.imgui_AcceptDragDropPayload(ctx, type, flags or 0)
end
f.EndDragDropTarget = function()
  ffi.C.imgui_EndDragDropTarget(ctx)
end

-- Clipping
f.PushClipRect = function(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
  ffi.C.imgui_PushClipRect(ctx, clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
end
f.PopClipRect = function()
  ffi.C.imgui_PopClipRect(ctx)
end

-- Focus, Activation
f.SetItemDefaultFocus = function()
  ffi.C.imgui_SetItemDefaultFocus(ctx)
end
f.SetKeyboardFocusHere = function(offset)
  ffi.C.imgui_SetKeyboardFocusHere(ctx, offset or IntZero)
end

-- Utilities
f.IsItemHovered = function(flags)
  return ffi.C.imgui_IsItemHovered(ctx, flags or IntZero)
end
f.IsItemActive = function()
  return ffi.C.imgui_IsItemActive(ctx)
end
f.IsItemFocused = function()
  return ffi.C.imgui_IsItemFocused(ctx)
end
f.IsItemClicked = function(mouse_button)
  return ffi.C.imgui_IsItemClicked(ctx, mouse_button or IntZero)
end
f.IsItemVisible = function()
  return ffi.C.imgui_IsItemVisible(ctx)
end
f.IsItemDeactivated = function()
  return ffi.C.imgui_IsItemDeactivated(ctx)
end
f.IsItemDeactivatedAfterChange = function()
  return ffi.C.imgui_IsItemDeactivatedAfterChange(ctx)
end
f.IsAnyItemHovered = function()
  return ffi.C.imgui_IsAnyItemHovered(ctx)
end
f.IsAnyItemActive = function()
  return ffi.C.imgui_IsAnyItemActive(ctx)
end
f.IsAnyItemFocused = function()
  return ffi.C.imgui_IsAnyItemFocused(ctx)
end
f.GetItemRectMin = function(res)
  ffi.C.imgui_GetItemRectMin(ctx, res)
end
f.GetItemRectMax = function(res)
  ffi.C.imgui_GetItemRectMax(ctx, res)
end
f.GetItemRectSize = function(v)
  ffi.C.imgui_GetItemRectSize(ctx, v)
end
f.SetItemAllowOverlap = function()
  ffi.C.imgui_SetItemAllowOverlap(ctx)
end
f.IsRectVisible1 = function(size)
  return ffi.C.imgui_IsRectVisible1(ctx, size)
end
f.IsRectVisible2 = function(rect_min, rect_max)
  return ffi.C.imgui_IsRectVisible2(ctx, rect_min, rect_max)
end
f.GetTime = function()
  return ffi.C.imgui_GetTime(ctx)
end
f.GetFrameCount = function()
  return ffi.C.imgui_GetFrameCount(ctx)
end
f.GetOverlayDrawList = function()
  return ffi.C.imgui_GetOverlayDrawList(ctx)
end
f.GetDrawListSharedData = function()
  return ffi.C.imgui_GetDrawListSharedData(ctx)
end
f.SetStateStorage = function(storage)
  ffi.C.imgui_SetStateStorage(ctx, storage)
end
f.GetStateStorage = function()
  return ffi.C.imgui_GetStateStorage(ctx)
end
f.CalcTextSize = function(res, text, text_end, hide_text_after_double_hash, wrap_width)
  ffi.C.imgui_CalcTextSize(ctx, text, text_end or nil, hide_text_after_double_hash or BoolFalse, wrap_width or FloatNegOne)
end
f.CalcListClipping = function(items_count, items_height, out_items_display_start, out_items_display_end)
  ffi.C.imgui_CalcListClipping(ctx, items_count, items_height, out_items_display_start, out_items_display_end)
end

f.BeginChildFrame = function(id, size, flags)
  return ffi.C.imgui_BeginChildFrame(ctx, id, size, flags)
end
f.EndChildFrame = function()
  ffi.C.imgui_EndChildFrame(ctx)
end

f.ColorConvertU32ToFloat4 = function(res, inU32)
  ffi.C.imgui_ColorConvertU32ToFloat4(res, inU32)
end
f.ColorConvertFloat4ToU32 = function(inU32)
  return ffi.C.imgui_ColorConvertFloat4ToU32(inU32)
end
f.ColorConvertRGBtoHSV = function(r, g, b, out_h, out_s, out_v)
  ffi.C.imgui_ColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v)
end
f.ColorConvertHSVtoRGB = function(h ,s ,v, a )
  local col = ImVec4(0,0,0, a or 1)
  ffi.C.imgui_ColorConvertHSVtoRGB(h,s,v, col)
  return col
end

-- Inputs
f.GetKeyIndex = function(imgui_key)
  return ffi.C.imgui_GetKeyIndex(ctx, imgui_key)
end
f.IsKeyDown = function(user_key_index)
  return ffi.C.imgui_IsKeyDown(ctx, user_key_index)
end
f.IsKeyPressed = function(user_key_index, repeated)
  return ffi.C.imgui_IsKeyPressed(ctx, user_key_index, repeated and BoolTrue or BoolFalse)
end
f.IsKeyReleased = function(user_key_index)
  return ffi.C.imgui_IsKeyReleased(ctx, user_key_index)
end
f.GetKeyPressedAmount = function(key_index, repeat_delay, rate)
  return ffi.C.imgui_GetKeyPressedAmount(ctx, key_index, repeat_delay, rate)
end
f.IsMouseDown = function(button)
  return ffi.C.imgui_IsMouseDown(ctx, button)
end
f.IsAnyMouseDown = function()
  return ffi.C.imgui_IsAnyMouseDown(ctx)
end
f.IsMouseClicked = function(button, repeated)
  return ffi.C.imgui_IsMouseClicked(ctx, button, repeated or BoolFalse)
end
f.IsMouseDoubleClicked = function(button)
  return ffi.C.imgui_IsMouseDoubleClicked(ctx, button)
end
f.IsMouseReleased = function(button)
  return ffi.C.imgui_IsMouseReleased(ctx, button)
end
f.IsMouseDragging = function(button, lock_threshold)
  return ffi.C.imgui_IsMouseDragging(ctx, button or IntZero, lock_threshold or -1.0)
end
f.IsMouseHoveringRect = function(r_min, r_max, clip)
  return ffi.C.imgui_IsMouseHoveringRect(ctx, r_min, r_max, clip and BoolTrue or BoolFalse)
end
f.IsMousePosValid = function(mouse_pos)
  return ffi.C.imgui_IsMousePosValid(ctx, mouse_pos or nil)
end
f.GetMousePos = function(res)
  ffi.C.imgui_GetMousePos(ctx, res)
end
f.GetMousePosOnOpeningCurrentPopup = function(res)
  ffi.C.imgui_GetMousePosOnOpeningCurrentPopup(ctx, res)
end
f.GetMouseDragDelta = function(res, button, lock_threshold)
  ffi.C.imgui_GetMouseDragDelta(ctx, res, button, lock_threshold)
end
f.ResetMouseDragDelta = function(button)
  ffi.C.imgui_ResetMouseDragDelta(ctx, button)
end
f.GetMouseCursor = function(res)
  ffi.C.imgui_GetMouseCursor(ctx, res)
end
f.SetMouseCursor = function(type)
  ffi.C.imgui_SetMouseCursor(ctx, type)
end
f.CaptureKeyboardFromApp = function(capture)
  ffi.C.imgui_CaptureKeyboardFromApp(ctx, capture)
end
f.CaptureMouseFromApp = function(capture)
  ffi.C.imgui_CaptureMouseFromApp(ctx, capture)
end

-- Clipboard Utilities
f.GetClipboardText = function()
  return ffi.C.imgui_GetClipboardText(ctx)
end
f.SetClipboardText = function(text)
  ffi.C.imgui_SetClipboardText(ctx, text)
end

-- Settings/.Ini Utilities
f.LoadIniSettingsFromDisk = function(ini_filename)
  ffi.C.imgui_LoadIniSettingsFromDisk(ctx, ini_filename)
end
f.LoadIniSettingsFromMemory = function(ini_data, ini_size)
  ffi.C.imgui_LoadIniSettingsFromMemory(ctx, ini_data, ini_size)
end
f.SaveIniSettingsToDisk = function(ini_filename)
  ffi.C.imgui_SaveIniSettingsToDisk(ctx, ini_filename)
end
f.SaveIniSettingsToMemory = function(out_ini_size)
  return ffi.C.imgui_SaveIniSettingsToMemory(ctx, out_ini_size)
end

--
f.Scrollbar = function(direction)
  ffi.C.imgui_Scrollbar(ctx, direction)
end

-- Member functions
f.ImDrawList_AddRect = function(drawList, vec2A, vec2B, col, rounding, rounding_corners_flags, thickness)
  ffi.C.imgui_ImDrawList_AddRect(drawList, vec2A, vec2B, col, rounding or 0.0, rounding_corners_flags or f.ImDrawCornerFlags("ImDrawCornerFlags_All"), thickness or 1.0)
end
f.ImDrawList_AddRectFilled = function(drawList, vec2A, vec2B, col, rounding, rounding_corners_flags)
  ffi.C.imgui_ImDrawList_AddRectFilled(drawList, vec2A, vec2B, col, rounding or 0.0, rounding_corners_flags or f.ImDrawCornerFlags("ImDrawCornerFlags_All"))
end
f.ImDrawList_AddText1 = function(drawList, pos, col, text_begin, text_end)
  ffi.C.imgui_ImDrawList_AddText1(drawList, pos, col, text_begin, text_end or nil)
end
f.ImDrawList_AddText2 = function(drawList, font, font_size, pos, col, text_begin, text_end, wrap_width, cpu_fine_clip_rect)
  ffi.C.imgui_ImDrawList_AddText2(drawList, font, font_size, pos, col, text_begin, text_end or nil, wrap_width or FloatZero, cpu_fine_clip_rect or nil)
end
f.ImDrawList_AddImage = function(drawList, user_texture_id, a, b, uv_a, uv_b, col)
  ffi.C.imgui_ImDrawList_AddImage(drawList, user_texture_id, a, b, uv_a or ImVec2Zero, uv_b or ImVec2One, col or ffi.new('ImU32', 0xFFFFFFFF))
end
f.ImGuiTextFilter_Draw = function(textFilter, label, width)
  return ffi.C.imgui_ImGuiTextFilter_Draw(textFilter, ctx, label or "Filter (inc,-exc)", width or FloatZero)
end


-- Helper functions
  -- Imgui Helper
f.GetImGuiIO_FontAllowUserScaling = function()
  return ffi.C.imgui_GetImGuiIO_FontAllowUserScaling(ctx)
end
f.ImGuiIO_KeyCtrl = function()
  return ffi.C.imgui_ImGuiIO_KeyCtrl(ctx)
end
f.ImGuiIO_DeltaTime = function()
  return ffi.C.imgui_ImGuiIO_DeltaTime(ctx)
end
f.ImGuiStyle_ItemSpacing = function(res)
  ffi.C.imgui_ImGuiStyle_ItemSpacing(ctx, res)
end
f.ImGuiStyle_ItemInnerSpacing = function(res)
  ffi.C.imgui_ImGuiStyle_ItemInnerSpacing(ctx, res)
end

  --
f.ShowHelpMarker = function(desc)
  f.TextDisabled("(?)")
  if f.IsItemHovered() then
    f.BeginTooltip()
    f.PushTextWrapPos(f.GetFontSize() * 35.0)
    f.TextUnformatted(desc)
    f.PopTextWrapPos()
    f.EndTooltip();
  end
end

  --PlotLines helper
f.GetTableLength = function(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

f.TableToArrayFloat = function( tbl )
  local array = ffi.new("float[?]", f.GetTableLength(tbl))
  for k,v in pairs(tbl) do
    array[k - 1] = v
  end
  return array
end

f.PlotLinesTbl = function( label, tbl, value, values_offset, overlay_text, scale_min, scale_max, graph_size )
  table.remove(tbl, 1)
  table.insert( tbl, value )
  local arr = TableToArrayFloat( tbl )
  ffi.C.imgui_PlotLines1( label, arr , GetLengthArrayFloat(arr), values_offset, overlay_text, scale_min, scale_max, graph_size )
end

f.CreateTable = function(size)
  local tbl = {}
  for i = 1, size, 1 do
    tbl[i] = 0
  end
  return tbl
end

f.ImVec4ToFloatPtr = function(imVec4)
  return ffi.cast("float*", imVec4)
end

-- public interface for imgui
-- M.f = f
-- types
M.voidPtr = voidPtr
M.Bool = Bool
M.BoolPtr = BoolPtr
M.CharPtr = CharPtr
M.Int = Int
M.IntPtr = IntPtr
M.Float = Float
M.FloatPtr = FloatPtr
M.Double = Double
M.DoublePtr = DoublePtr
M.ArrayBoolByTbl = ArrayBoolByTbl
M.ArrayBoolPtrByTbl = ArrayBoolPtrByTbl
M.ArrayIntPtrByTbl = ArrayIntPtrByTbl
M.ArrayChar = ArrayChar
M.ArrayFloat = ArrayFloat
M.ArrayFloatByTbl = ArrayFloatByTbl
M.ArrayInt = ArrayInt
M.ArrayImVec4 = ArrayImVec4
  -- imgui specific types
M.ImVec2 = ImVec2
M.ImVec2Ptr = ImVec2Ptr
M.ImVec3 = ImVec3
M.ImVec3Ptr = ImVec3Ptr
M.ImVec4 = ImVec4
M.ImVec4Ptr = ImVec4Ptr
M.ImColorByRGB = ImColorByRGB
-- enums
M.ImGuiLayoutType = f.ImGuiLayoutType
M.ImGuiWindowFlags = f.ImGuiWindowFlags
M.ImGuiInputTextFlags = f.ImGuiInputTextFlags
M.ImGuiComboFlags = f.ImGuiComboFlags
M.ImGuiCol = f.ImGuiCol
M.ImDrawCornerFlags = f.ImDrawCornerFlags
M.ImGuiCond = f.ImGuiCond
M.ImGuiSelectableFlags = f.ImGuiSelectableFlags
M.ImGuiTreeNodeFlags = f.ImGuiTreeNodeFlags
M.ImGuiHoveredFlags = f.ImGuiHoveredFlags
M.ImGuiColorEditFlags = f.ImGuiColorEditFlags
M.ImGuiKey = f.ImGuiKey
M.ImGuiDataType = f.ImGuiDataType
M.ImGuiDir = f.ImGuiDir
M.ImGuiStyleVar = f.ImGuiStyleVar
M.ImGuiColumnsFlags = f.ImGuiColumnsFlags
M.ImGuiDragDropFlags = f.ImGuiDragDropFlags
M.ImFontAtlasFlags = f.ImFontAtlasFlags
M.ImDrawListFlags = f.ImDrawListFlags
M.ImGuiConfigFlags = f.ImGuiConfigFlags
M.ImGuiBackendFlags = f.ImGuiBackendFlags
M.ImGuiNavInput = f.ImGuiNavInput
M.ImGuiFocusedFlags = f.ImGuiFocusedFlags

-- Functions
-- Context creation and access
M.CreateContext = ffi.C.ImGui_CreateContext
M.GetMainContext = f.ImGui_GetMainContext
-- Main
M.CreateIO = f.CreateIO
M.GetIO = f.GetIO
M.GetStyle = f.GetStyle
-- Demo, Debug, Information
M.ShowDemoWindow = f.ShowDemoWindow
M.ShowMetricsWindow = f.ShowMetricsWindow
M.ShowStyleEditor = f.ShowStyleEditor
M.ShowStyleSelector = f.ShowStyleSelector
M.ShowFontSelector = f.ShowFontSelector
M.ShowUserGuide = f.ShowUserGuide
M.GetVersion = f.GetVersion
-- Style
M.StyleColorsDark = f.StyleColorsDark
M.StyleColorsClassic = f.StyleColorsClassic
M.StyleColorsLight = f.StyleColorsLight
-- Windows
M.Begin = f.Begin
M.End = f.End
M.BeginChild1 = f.BeginChild1
M.BeginChild2 = f.BeginChild2
M.EndChild = f.EndChild
-- Windows: Utilities
M.IsWindowAppearing = f.IsWindowAppearing
M.IsWindowCollapsed = f.IsWindowCollapsed
M.IsWindowFocused = f.IsWindowFocused
M.IsWindowHovered = f.IsWindowHovered
M.GetWindowDrawList = f.GetWindowDrawList
M.GetWindowPos = f.GetWindowPos
M.GetWindowWidth = f.GetWindowWidth
M.GetWindowHeight = f.GetWindowHeight
M.GetContentRegionMax = f.GetContentRegionMax
M.GetContentRegionAvail = f.GetContentRegionAvail
M.GetContentRegionAvailWidth = f.GetContentRegionAvailWidth
M.GetWindowContentRegionMin = f.GetWindowContentRegionMin
M.GetWindowContentRegionMax = f.GetWindowContentRegionMax
M.GetWindowContentRegionWidth = f.GetWindowContentRegionWidth

M.SetNextWindowPos = f.SetNextWindowPos
M.SetNextWindowSize = f.SetNextWindowSize
M.SetNextWindowSizeConstraints = f.SetNextWindowSizeConstraints
M.SetNextWindowContentSize = f.SetNextWindowContentSize
M.SetNextWindowCollapsed = f.SetNextWindowCollapsed
M.SetNextWindowFocus = f.SetNextWindowFocus
M.SetNextWindowBgAlpha = f.SetNextWindowBgAlpha
M.SetWindowPos1 = f.SetWindowPos1
M.SetWindowSize1 = f.SetWindowSize1
M.SetWindowCollapsed1 = f.SetWindowCollapsed1
M.SetWindowFocus1 = f.SetWindowFocus1
M.SetWindowFontScale = f.SetWindowFontScale
M.SetWindowPos2 = f.SetWindowPos2
M.SetWindowSize2 = f.SetWindowSize2
M.SetWindowCollapsed2 = f.SetWindowCollapsed2
M.SetWindowFocus2 = f.SetWindowFocus2
-- Windows Scrolling
M.GetScrollX = f.GetScrollX
M.GetScrollY = f.GetScrollY
M.GetScrollMaxX = f.GetScrollMaxX
M.GetScrollMaxY = f.GetScrollMaxY
M.SetScrollX = f.SetScrollX
M.SetScrollY = f.SetScrollY
M.SetScrollHere = f.SetScrollHere
M.SetScrollFromPosY = f.SetScrollFromPosY
-- Parameters stacks (shared)
M.PushFont = f.PushFont
M.PopFont = f.PopFont
M.PushStyleColor1 = f.PushStyleColor1
M.PushStyleColor2 = f.PushStyleColor2
M.PopStyleColor = f.PopStyleColor
M.PushStyleVar1 = f.PushStyleVar1
M.PushStyleVar2 = f.PushStyleVar2
M.PopStyleVar = f.PopStyleVar
M.GetStyleColorVec4 = f.GetStyleColorVec4
M.GetFont = f.GetFont
M.GetFontSize = f.GetFontSize
M.GetFontTexUvWhitePixel = f.GetFontTexUvWhitePixel
M.GetColorU321 = f.GetColorU321
M.GetColorU322 = f.GetColorU322
M.GetColorU323 = f.GetColorU323
-- Parameters stacks (current window)
M.PushItemWidth = f.PushItemWidth
M.PopItemWidth = f.PopItemWidth
M.PushTextWrapPos = f.PushTextWrapPos
M.PopTextWrapPos = f.PopTextWrapPos
-- Cursor / Layout
M.Separator = f.Separator
M.SameLine = f.SameLine
M.NewLine = f.NewLine
M.Spacing = f.Spacing
M.Dummy = f.Dummy
M.Indent = f.Indent
M.Unindent = f.Unindent
M.BeginGroup = f.BeginGroup
M.EndGroup = f.EndGroup
M.GetCursorPos = f.GetCursorPos
M.GetCursorPosX = f.GetCursorPosX
M.GetCursorPosY = f.GetCursorPosY
M.SetCursorPos = f.SetCursorPos
M.SetCursorPosX = f.SetCursorPosX
M.SetCursorPosY = f.SetCursorPosY
M.GetCursorStartPos = f.GetCursorStartPos
M.GetCursorScreenPos = f.GetCursorScreenPos
M.SetCursorScreenPos = f.SetCursorScreenPos
M.AlignTextToFramePadding = f.AlignTextToFramePadding
M.GetTextLineHeight = f.GetTextLineHeight
M.GetTextLineHeightWithSpacing = f.GetTextLineHeightWithSpacing
M.GetFrameHeight = f.GetFrameHeight
M.GetFrameHeightWithSpacing = f.GetFrameHeightWithSpacing
-- ID stack/scopes
M.PushID1 = f.PushID1
M.PushID2 = f.PushID2
M.PushID3 = f.PushID3
M.PushID4 = f.PushID4
M.PopID = f.PopID
M.GetID1 = f.GetID1
M.GetID2 = f.GetID2
M.GetID3 = f.GetID3
-- Widgets: Text
M.TextUnformatted = f.TextUnformatted
M.Text = f.Text
M.TextColored = f.TextColored
M.TextDisabled = f.TextDisabled
M.TextWrapped = f.TextWrapped
M.LabelText = f.LabelText
M.BulletText = f.BulletText
-- Widgets: Main
M.Button = f.Button
M.SmallButton = f.SmallButton
M.ArrowButton = f.ArrowButton
M.InvisibleButton = f.InvisibleButton
M.Image = f.Image
M.ImageButton = f.ImageButton
M.Checkbox = f.Checkbox
M.CheckboxFlags = f.CheckboxFlags
M.RadioButton1 = f.RadioButton1
M.RadioButton2 = f.RadioButton2
M.PlotLines1 = f.PlotLines1
M.PlotLines2 = f.PlotLines2
M.PlotHistogram1 = f.PlotHistogram1
M.PlotHistogram2 = f.PlotHistogram2
M.ProgressBar = f.ProgressBar
M.Bullet = f.Bullet
-- Widgets: Combo Box
M.BeginCombo = f.BeginCombo
M.EndCombo = f.EndCombo
M.Combo1 = f.Combo1
M.Combo2 = f.Combo2
-- Widgets: Drags
M.DragFloat = f.DragFloat
M.DragFloat2 = f.DragFloat2
M.DragFloat3 = f.DragFloat3
M.DragFloat4 = f.DragFloat4
M.DragFloatRange2 = f.DragFloatRange2
M.DragInt = f.DragInt
M.DragInt2 = f.DragInt2
M.DragInt3 = f.DragInt3
M.DragInt4 = f.DragInt4
M.DragIntRange2 = f.DragIntRange2
M.DragScalar = f.DragScalar
M.DragScalarN = f.DragScalarN
-- Widgets: Input with Keyboard
M.InputText = f.InputText
M.InputTextMultiline = f.InputTextMultiline
M.InputTextMultilineReadOnly = f.InputTextMultilineReadOnly
M.InputFloat = f.InputFloat
M.InputFloat2 = f.InputFloat2
M.InputFloat3 = f.InputFloat3
M.InputFloat4 = f.InputFloat4
M.InputInt = f.InputInt
M.InputInt2 = f.InputInt2
M.InputInt3 = f.InputInt3
M.InputInt4 = f.InputInt4
M.InputDouble = f.InputDouble
M.InputScalar = f.InputScalar
M.InputScalarN = f.InputScalarN
-- Widgets: Sliders
M.SliderFloat = f.SliderFloat
M.SliderFloat2 = f.SliderFloat2
M.SliderFloat3 = f.SliderFloat3
M.SliderFloat4 = f.SliderFloat4
M.SliderAngle = f.SliderAngle
M.SliderInt = f.SliderInt
M.SliderInt2 = f.SliderInt2
M.SliderInt3 = f.SliderInt3
M.SliderInt4 = f.SliderInt4
M.SliderScalar = f.SliderScalar
M.SliderScalarN = f.SliderScalarN
M.VSliderFloat = f.VSliderFloat
M.VSliderInt = f.VSliderInt
M.VSliderScalar = f.VSliderScalar
-- Widgets: Color Editor/Picker
M.ColorEdit3 = f.ColorEdit3
M.ColorEdit4 = f.ColorEdit4
M.ColorPicker3 = f.ColorPicker3
M.ColorPicker4 = f.ColorPicker4
M.ColorButton = f.ColorButton
M.SetColorEditOptions = f.SetColorEditOptions
-- Widgets: Trees
M.TreeNode1 = f.TreeNode1
M.TreeNode2 = f.TreeNode2
M.TreeNode3 = f.TreeNode3
M.TreeNodeV1 = f.TreeNodeV1
M.TreeNodeV2 = f.TreeNodeV2
M.TreeNodeEx1 = f.TreeNodeEx1
M.TreeNodeEx2 = f.TreeNodeEx2
M.TreeNodeEx3 = f.TreeNodeEx3
M.TreeNodeExV1 = f.TreeNodeExV1
M.TreeNodeExV2 = f.TreeNodeExV2
M.TreePush1 = f.TreePush1
M.TreePush2 = f.TreePush2
M.TreePop = f.TreePop
M.TreeAdvanceToLabelPos = f.TreeAdvanceToLabelPos
M.GetTreeNodeToLabelSpacing = f.GetTreeNodeToLabelSpacing
M.SetNextTreeNodeOpen = f.SetNextTreeNodeOpen
M.CollapsingHeader1 = f.CollapsingHeader1
M.CollapsingHeader2 = f.CollapsingHeader2
-- Widgets: Selectable / Lists
M.Selectable1 = f.Selectable1
M.Selectable2 = f.Selectable2
M.ListBox = f.ListBox
M.ListBoxHeader1 = f.ListBoxHeader1
M.ListBoxHeader2 = f.ListBoxHeader2
M.ListBoxFooter = f.ListBoxFooter
-- Widgets: Value() Helpers
M.Value1 = f.Value1
M.Value2 = f.Value2
M.Value3 = f.Value3
M.Value4 = f.Value4
-- Tooltips
M.SetTooltip = f.SetTooltip
M.BeginTooltip = f.BeginTooltip
M.EndTooltip = f.EndTooltip
-- Menus
M.BeginMainMenuBar = f.BeginMainMenuBar
M.EndMainMenuBar = f.EndMainMenuBar
M.BeginMenuBar = f.BeginMenuBar
M.EndMenuBar = f.EndMenuBar
M.BeginMenu = f.BeginMenu
M.EndMenu = f.EndMenu
M.MenuItem1 = f.MenuItem1
M.MenuItem2 = f.MenuItem2
-- Popups
M.OpenPopup = f.OpenPopup
M.BeginPopup = f.BeginPopup
M.BeginPopupContextItem = f.BeginPopupContextItem
M.BeginPopupContextWindow = f.BeginPopupContextWindow
M.BeginPopupContextVoid = f.BeginPopupContextVoid
M.BeginPopupModal = f.BeginPopupModal
M.EndPopup = f.EndPopup
M.OpenPopupOnItemClick = f.OpenPopupOnItemClick
M.IsPopupOpen = f.IsPopupOpen
M.CloseCurrentPopup = f.CloseCurrentPopup
-- Columns
M.Columns = f.Columns
M.NextColumn = f.NextColumn
M.GetColumnIndex = f.GetColumnIndex
M.GetColumnWidth = f.GetColumnWidth
M.SetColumnWidth = f.SetColumnWidth
M.GetColumnOffset = f.GetColumnOffset
M.SetColumnOffset = f.SetColumnOffset
M.GetColumnsCount = f.GetColumnsCount
M.BeginColumns = f.BeginColumns
M.EndColumns = f.EndColumns
-- Logging/Capture
M.LogToTTY = f.LogToTTY
M.LogToFile = f.LogToFile
M.LogToClipboard = f.LogToClipboard
M.LogFinish = f.LogFinish
M.LogButtons = f.LogButtons
M.LogText = f.LogText
-- Drag and Drop
M.BeginDragDropSource = f.BeginDragDropSource
M.SetDragDropPayload = f.SetDragDropPayload
M.EndDragDropSource = f.EndDragDropSource
M.BeginDragDropTarget = f.BeginDragDropTarget
M.AcceptDragDropPayload = f.AcceptDragDropPayload
M.EndDragDropTarget = f.EndDragDropTarget
-- Clipping
M.PushClipRect = f.PushClipRect
M.PopClipRect = f.PopClipRect
-- Focus, Activation
M.SetItemDefaultFocus = f.SetItemDefaultFocus
M.SetKeyboardFocusHere = f.SetKeyboardFocusHere
-- Utilities
M.IsItemHovered = f.IsItemHovered
M.IsItemActive = f.IsItemActive
M.IsItemFocused = f.IsItemFocused
M.IsItemClicked = f.IsItemClicked
M.IsItemVisible = f.IsItemVisible
M.IsItemDeactivated = f.IsItemDeactivated
M.IsItemDeactivatedAfterChange = f.IsItemDeactivatedAfterChange
M.IsAnyItemHovered = f.IsAnyItemHovered
M.IsAnyItemActive = f.IsAnyItemActive
M.IsAnyItemFocused = f.IsAnyItemFocused
M.GetItemRectMin = f.GetItemRectMin
M.GetItemRectMax = f.GetItemRectMax
M.GetItemRectSize = f.GetItemRectSize
M.SetItemAllowOverlap = f.SetItemAllowOverlap
M.IsRectVisible1 = f.IsRectVisible1
M.IsRectVisible2 = f.IsRectVisible2
M.GetTime = f.GetTime
M.GetFrameCount = f.GetFrameCount
M.GetOverlayDrawList = f.GetOverlayDrawList
M.GetDrawListSharedData = f.GetDrawListSharedData
M.GetStyleColorName = ffi.C.imgui_GetStyleColorName
M.SetStateStorage = f.SetStateStorage
M.GetStateStorage = f.GetStateStorage
M.CalcTextSize = f.CalcTextSize
M.CalcListClipping = f.CalcListClipping

M.BeginChildFrame = f.BeginChildFrame
M.EndChildFrame = f.EndChildFrame

M.ColorConvertU32ToFloat4 = f.ColorConvertU32ToFloat4
M.ColorConvertFloat4ToU32 = f.ColorConvertFloat4ToU32
M.ColorConvertRGBtoHSV = f.ColorConvertRGBtoHSV
M.ColorConvertHSVtoRGB = f.ColorConvertHSVtoRGB
-- Inputs
M.GetKeyIndex = f.GetKeyIndex
M.IsKeyDown = f.IsKeyDown
M.IsKeyPressed = f.IsKeyPressed
M.IsKeyReleased = f.IsKeyReleased
M.GetKeyPressedAmount = f.GetKeyPressedAmount
M.IsMouseDown = f.IsMouseDown
M.IsAnyMouseDown = f.IsAnyMouseDown
M.IsMouseClicked = f.IsMouseClicked
M.IsMouseDoubleClicked = f.IsMouseDoubleClicked
M.IsMouseReleased = f.IsMouseReleased
M.IsMouseDragging = f.IsMouseDragging
M.IsMouseHoveringRect = f.IsMouseHoveringRect
M.IsMousePosValid = f.IsMousePosValid
M.GetMousePos = f.GetMousePos
M.GetMousePosOnOpeningCurrentPopup = f.GetMousePosOnOpeningCurrentPopup
M.GetMouseDragDelta = f.GetMouseDragDelta
M.ResetMouseDragDelta = f.ResetMouseDragDelta
M.GetMouseCursor = f.GetMouseCursor
M.SetMouseCursor = f.SetMouseCursor
M.CaptureKeyboardFromApp = f.CaptureKeyboardFromApp
M.CaptureMouseFromApp = f.CaptureMouseFromApp
-- Clipboard Utilities
M.GetClipboardText = f.GetClipboardText
M.SetClipboardText = f.SetClipboardText
-- Settings/.Ini Utilities
M.LoadIniSettingsFromDisk = f.LoadIniSettingsFromDisk
M.LoadIniSettingsFromMemory = f.LoadIniSettingsFromMemory
M.SaveIniSettingsToDisk = f.SaveIniSettingsToDisk
M.SaveIniSettingsToMemory = f.SaveIniSettingsToMemory
--
M.Scrollbar = f.Scrollbar

-- Member functions
-- ImDrawList
M.ImDrawList_AddRect = f.ImDrawList_AddRect
M.ImDrawList_AddRectFilled = f.ImDrawList_AddRectFilled
M.ImDrawList_AddText1 = f.ImDrawList_AddText1
M.ImDrawList_AddText2 = f.ImDrawList_AddText2
M.ImDrawList_AddImage = f.ImDrawList_AddImage
-- ImGuiTextFilter
M.ImGuiTextFilter_Draw = f.ImGuiTextFilter_Draw
-- Helper functions
M.GetImGuiIO_FontAllowUserScaling = f.GetImGuiIO_FontAllowUserScaling
M.ImGuiIO_KeyCtrl = f.ImGuiIO_KeyCtrl
M.ImGuiIO_DeltaTime = f.ImGuiIO_DeltaTime
M.ImGuiStyle_ItemSpacing = f.ImGuiStyle_ItemSpacing
M.ImGuiStyle_ItemInnerSpacing = f.ImGuiStyle_ItemInnerSpacing
M.ImGuiIO_Fonts_TexWidth = ffi.C.imgui_ImGuiIO_Fonts_TexWidth
M.ImGuiIO_Fonts_TexHeight = ffi.C.imgui_ImGuiIO_Fonts_TexHeight
M.ImGuiIO_Fonts_TexID = ffi.C.imgui_ImGuiIO_Fonts_TexID
M.ImGuiIO_MousePos = ffi.C.imgui_ImGuiIO_MousePos
  --
M.ShowHelpMarker = f.ShowHelpMarker

local function wrpTest(fn, ... )
  fn(context, unpack({...}) )
end

local imguiReady = false

--TODO: Create event for initialization and when reloading lua
local function onImGuiReady()
  -- create new context
  if vmType == 'game' then
    -- get the 1st, initial c++ context that is managed by the game engine
    ctx = ffi.C.ImGui_GetMainContext()
  end
end

local function onExtensionLoaded()
  if vmType == 'game' then
    -- get the 1st, initial c++ context that is managed by the game engine
    ctx = ffi.C.ImGui_GetMainContext()
  else
    ctx = ffi.C.ImGui_CreateContext()
    ffi.C.ImGui_NewFrame(ctx)
  end
end

local function updateGFX()
  --if vmType ~= 'game' then
    ffi.C.ImGui_registerDrawData(ctx)
    ffi.C.ImGui_NewFrame(ctx)
  --end
end

-- Helper
-- define
M.FLT_MAX = FLT_MAX
-- variables
M.BoolTrue = BoolTrue
M.BoolFalse = BoolFalse
M.IntZero = IntZero
M.IntOne = IntOne
M.IntNegOne = IntNegOne
M.FloatZero = FloatZero
M.FloatOne = FloatOne
M.FloatNegOne = FloatNegOne
M.ImVec2Zero = ImVec2Zero
M.ImVec2One = ImVec2One
M.ImVec4Zero = ImVec4Zero
M.ImVec4One = ImVec4One
-- functions
M.ArraySize = f.ArraySize
M.GetLengthArrayBool = f.GetLengthArrayBool
M.GetLengthArrayFloat = f.GetLengthArrayFloat
M.GetLengthArrayInt = f.GetLengthArrayInt
M.GetLengthArrayCharPtr = f.GetLengthArrayCharPtr
M.GetLengthArrayImVec4 = f.GetLengthArrayImVec4
M.ArrayCharPtrByTbl = f.ArrayCharPtrByTbl

M.GetTableLength = f.GetTableLength
M.TableToArrayFloat = f.TableToArrayFloat
M.PlotLinesTbl = f.PlotLinesTbl
M.CreateTable = f.CreateTable
M.ImVec4ToFloatPtr = f.ImVec4ToFloatPtr

M.onImGuiReady = onImGuiReady
M.onExtensionLoaded = onExtensionLoaded

M.updateGFX = updateGFX

return M