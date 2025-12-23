require("recycle-bin"):setup()

require("kdeconnect-send"):setup({
    auto_select_single = false,
})
require("relative-motions"):setup({
  show_numbers = "relative_absolute",  
  show_motion  = true,        
  enter_mode   = "first"      
})
require("simple-tag"):setup({
  ui_mode = "icon",
  hints_disabled = false,
  linemode_order = 1000,

  tag_order = { "r", "o", "y", "g", "b", "p" },  -- Add this line!

  colors = {
    ["r"] = "#F85B52",
    ["o"] = "#F6A137",   
    ["y"] = "#F5CE35",   
    ["g"] = "#4ECF64",   
    ["b"] = "#378CF8",   
    ["p"] = "#B46FD4",   
  },

  icons = {
    default = "●",
    ["r"] = "●",
    ["o"] = "●",
    ["y"] = "●",
    ["g"] = "●",
    ["b"] = "●",
    ["p"] = "●",
  },
})
