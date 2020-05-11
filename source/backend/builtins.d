module backend.builtins;

immutable printBuiltin = `
static int print(const char *msg) {
    return printf(msg);
}
`;

immutable warnBuiltin = `
static int warn(const char *msg) {
    return fprintf(stderr, msg);
}
`;

immutable dieBuiltin = `
__attribute__((noreturn)) static int die(const char *msg) {
    fprintf(stderr, msg);
    exit(1);
}
`;

immutable rangeBuiltin = `
static int range(size_t (*func)(int), int min, int max) {
    for (int i = min; i < max; i++) {
        func(i);
    }

    return max - min;
}
`;
