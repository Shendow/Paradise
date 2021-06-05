// This is where you should add includes for additions, overrides or other specific behaviour when HRP_MODE is defined.
//
// As this file is included /after/ the main code, you can override the variables or procs of a class very easily.
// However, be careful that the main code does not depend on HRP code to function.
// If that is the case, move it to the main code directory.
#ifdef HRP_MODE
// Copy paste, uncomment and modify as needed, just don't put your overrides in this block, keep it in different files.
// #include "subdir/override1.dm"
#endif
