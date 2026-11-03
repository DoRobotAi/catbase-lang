#!/usr/bin/env perl
# fixzig.pl — post-process catcc-generated Zig files before the real zig runs.
#
# Fix 1 (upstream issue #5): f-string format literals emitted by catcc contain
#   raw \n \t \r bytes, raw quotes, or invalid single-backslash escapes inside a
#   Zig string literal -> "string literal contains invalid byte".
#   We re-escape only the initFmt(...)/initFmtWithStrip(...) format literals.
#   Valid escapes already present (e.g. \\n) are preserved; unknown escapes
#   (e.g. \d) become literal backslash + char, matching Python semantics.
#
# Fix 2 (upstream issue #6): struct local bindings are emitted as
#   `const s: State = State{...}`; a mutable call on a dict field
#   (s.counts["b"] = 2 -> s.counts.put(...)) then gets a *const receiver and
#   fails with "expected '*Dict', found '*const Dict'". We rewrite such
#   declarations to `var`, which keeps fields mutable. Only matches
#   `const <name>: <T> = <T>{` at 8-space indent (catcc's function-body level),
#   so inner blk/label consts and genuine non-struct consts are untouched.
use strict;
use warnings;

my $p = shift @ARGV or exit 0;
open(my $fh, '<', $p) or exit 0;
local $/;
my $s = <$fh>;
close $fh;

my $changed = 0;

# ---- Fix 1: escape f-string format literals ----
# match: initFmt(WithStrip)(runtime.getGlobalAllocator(), "<lit>", varExprs)
while ($s =~ /initFmt(?:WithStrip)?\(runtime\.getGlobalAllocator\(\), "/g) {
    my $head = pos($s);
    my $k = index($s, '", varExprs', $head);
    next if $k < 0;
    my $lit = substr($s, $head, $k - $head);
    next unless $lit =~ /[\n\t\r"\\]/;
    my $new = esc($lit);
    if ($new ne $lit) {
        substr($s, $head, $k - $head) = $new;
        pos($s) = $head + length($new);
        $changed = 1;
    }
}

sub esc {
    my ($lit) = @_;
    my %valid = map { $_ => 1 } split //, 'ntr"\'0';
    my $out = '';
    my $i = 0;
    my $n = length($lit);
    while ($i < $n) {
        my $ch = substr($lit, $i, 1);
        if ($ch eq "\n") { $out .= '\n'; }
        elsif ($ch eq "\t") { $out .= '\t'; }
        elsif ($ch eq "\r") { $out .= '\r'; }
        elsif ($ch eq '"')  { $out .= '\\"'; }
        elsif ($ch eq '\\') {
            my $nx = $i + 1 < $n ? substr($lit, $i + 1, 1) : '';
            if ($valid{$nx}) { $out .= '\\' . $nx; $i += 2; next; }
            else             { $out .= '\\\\'; }
        }
        else { $out .= $ch; }
        $i++;
    }
    return $out;
}

# ---- Fix 2: struct binding const -> var ----
# ^        const name: T = T{
my $LBRACE = chr(123);
my $nsub = ($s =~ s/^        const (\w+): (\w+) = \2$LBRACE/        var $1: $2 = $2$LBRACE/mg);
$changed = 1 if $nsub;

if ($changed) {
    open(my $out_fh, '>', $p) or exit 0;
    print $out_fh $s;
    close $out_fh;
}
