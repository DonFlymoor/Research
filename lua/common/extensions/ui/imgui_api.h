

///////////////////////////////////////////////////////////////////////////////
// this file is used for declaring C types for LuaJIT's FFI. Do not use it in C
///////////////////////////////////////////////////////////////////////////////


// this file needs to be in sync with imgui_api.lua


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
  ImGuiWindowFlags_None                       = 0,
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
  ImGuiColorEditFlags_None            = 0,
  ImGuiColorEditFlags_NoAlpha         = 1 << 1,
  ImGuiColorEditFlags_NoPicker        = 1 << 2,
  ImGuiColorEditFlags_NoOptions       = 1 << 3,
  ImGuiColorEditFlags_NoSmallPreview  = 1 << 4,
  ImGuiColorEditFlags_NoInputs        = 1 << 5,
  ImGuiColorEditFlags_NoTooltip       = 1 << 6,
  ImGuiColorEditFlags_NoLabel         = 1 << 7,
  ImGuiColorEditFlags_NoSidePreview   = 1 << 8,
  ImGuiColorEditFlags_NoDragDrop      = 1 << 9,
  ImGuiColorEditFlags_AlphaBar        = 1 << 16,
  ImGuiColorEditFlags_AlphaPreview    = 1 << 17,
  ImGuiColorEditFlags_AlphaPreviewHalf= 1 << 18,
  ImGuiColorEditFlags_HDR             = 1 << 19,
  ImGuiColorEditFlags_RGB             = 1 << 20,
  ImGuiColorEditFlags_HSV             = 1 << 21,
  ImGuiColorEditFlags_HEX             = 1 << 22,
  ImGuiColorEditFlags_Uint8           = 1 << 23,
  ImGuiColorEditFlags_Float           = 1 << 24,
  ImGuiColorEditFlags_PickerHueBar    = 1 << 25,
  ImGuiColorEditFlags_PickerHueWheel  = 1 << 26,
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

typedef struct ImTextureHandler {
  const void* ptr_do_not_use;
} ImTextureHandler;

void ImTextureHandler_set(ImTextureHandler *hnd, const char *path);
ImTextureID ImTextureHandler_get(ImTextureHandler *hnd);
void ImTextureHandler_size(ImTextureHandler *hnd, ImVec2 *vec2);

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
ImGuiContext* ImGui_CreateContext(int id);
ImGuiContext* ImGui_GetMainContext();
void ImGui_NewFrame(ImGuiContext* ctx, int queueId);
void ImGui_registerDrawData(ImGuiContext* ctx, int queueId);
void imgui_SetCurrentContext(ImGuiContext* ctx);
ImGuiIO* imgui_CreateIO(ImGuiContext& g);
void imgui_GetIO(ImGuiContext& g, ImGuiIO* res);
void imgui_SetStyle(ImGuiContext& g, ImGuiStyle* style);
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
void imgui_ImDrawList_AddTriangleFilled(ImDrawList *obj, const ImVec2& a, const ImVec2& b, const ImVec2& c, ImU32 col);
void imgui_ImDrawList_AddText1(ImDrawList *obj, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end);
void imgui_ImDrawList_AddText2(ImDrawList *obj, const ImFont* font, float font_size, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end, float wrap_width, const ImVec4* cpu_fine_clip_rect);
void imgui_ImDrawList_AddImage(ImDrawList *obj, ImTextureID user_texture_id, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, ImU32 col);
bool imgui_ImGuiTextFilter_Draw(ImGuiTextFilter *obj, ImGuiContext& g, const char* label, float width);
bool imgui_ImGuiTextFilter_PassFilter(ImGuiTextFilter *obj, ImGuiContext& g, const char* text);
void imgui_ImGuiTextFilter_Clear(ImGuiTextFilter *obj, ImGuiContext& g);

// Helper functions
bool imgui_GetImGuiIO_FontAllowUserScaling(ImGuiContext& g);
bool imgui_ImGuiIO_KeyCtrl(ImGuiContext& g);
bool imgui_ImGuiIO_KeyShift(ImGuiContext& g);
bool imgui_ImGuiIO_KeyAlt(ImGuiContext& g);
float imgui_ImGuiIO_DeltaTime(ImGuiContext& g);
void imgui_ImGuiStyle_ItemSpacing(ImGuiContext& g, ImVec2* res);
void imgui_ImGuiStyle_ItemInnerSpacing(ImGuiContext& g, ImVec2* res);
void imgui_ImGuiIO_Fonts_AddFontDefault(ImGuiIO *imGuiIO, ImFont* res, const ImFontConfig* font_cfg);
void imgui_ImGuiIO_Fonts_AddFontFromFileTTF(ImGuiIO *imGuiIO, ImFont* res, const char* filename, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
int imgui_ImGuiIO_Fonts_TexWidth(ImGuiIO *imGuiIO);
int imgui_ImGuiIO_Fonts_TexHeight(ImGuiIO *imGuiIO);
void* imgui_ImGuiIO_Fonts_TexID(ImGuiIO *imGuiIO);
void imgui_ImGuiIO_MousePos(ImGuiIO *imGuiIO, ImVec2* res);
float imgui_ImGuiIO_MouseWheel(ImGuiContext& g);
bool imgui_ImGuiIO_WantCaptureMouse(ImGuiContext& g);

ImGuiWindow* imgui_GetWindow(ImGuiContext& g, int index);
void imgui_MinimizeAllWindows(ImGuiContext& g);
void imgui_MaximizeAllWindows(ImGuiContext& g);