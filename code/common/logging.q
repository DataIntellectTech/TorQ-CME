\d .lg

colours:(`ERROR`ERR`WRN`WARN`INF!("\033[1;31m";"\033[1;31m";"\033[0;33m";"\033[0;33m";"\033[0m"));
/ overrides .lg.format included in torq to add ccnsole colours for error and warn
format:{[loglevel;proctype;proc;id;message]((colours loglevel), "|" sv (string .proc.cp[];string .z.h;string proctype;string proc;string loglevel;string id;message)),"\033[0m"}


