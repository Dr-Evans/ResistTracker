package = "ResistTracker"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/Dr-Evans/ResistTracker.git"
}
description = {
   summary = "This addon tracks resists.",
   detailed = "This addon tracks resists.",
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ResistTracker = "src/ResistTracker.lua"
   }
}
