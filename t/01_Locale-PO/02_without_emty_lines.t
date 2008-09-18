#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw($FILE_LOCALE_PO_02 $DROP_TABLE);
use Test::More tests => 17;
eval 'use Test::Differences qw(eq_or_diff)';
if ($@) {
    *eq_or_diff = \&is;
    diag("Module Test::Differences not installed; $@");
}

BEGIN {
    require_ok('DBD::PO::Locale::PO');
}

# write po file
{
    open my $file, '> :encoding(utf-8)', $FILE_LOCALE_PO_02;
    isnt(
        $!,
        q{},
        'open file',
    );

    for (1 .. 2) {
        my $po = DBD::PO::Locale::PO->new(
            '-msgid'  => "id $_",
            '-msgstr' => "str $_",
        );
        isa_ok($po, 'DBD::PO::Locale::PO');

        my $dump = $po->dump();
        chomp $dump;
        ok(
            print($file $dump),
            'print file',
        );
    }
}

# check_table_file
{
    my $po = <<'EOT';
msgid "id 1"
msgstr "str 1"
msgid "id 2"
msgstr "str 2"
EOT
    local $/ = ();
    open my $file1,
         '< :encoding(utf-8)',
         $FILE_LOCALE_PO_02 or die $!;
    my $content1 = <$file1>;
    open my $file2, '< :encoding(utf-8)', \($po) or die $!;
    my $content2 = <$file2>;
    eq_or_diff($content1, $content2, 'check po file');
}

# read table file
{
    open my $file, '< :encoding(utf-8)', $FILE_LOCALE_PO_02;
    isnt(
        $!,
        q{},
        'open file',
    );

    my $line_number = 0;
    for (1 .. 2) {
        my $po = DBD::PO::Locale::PO->load_entry(
            $FILE_LOCALE_PO_02,
            $file,
            \$line_number,
        );
        isa_ok($po, 'DBD::PO::Locale::PO');
        is(
            $po->loaded_line_number(),
            {1 => 1, 2 => 3}->{$_},
            'loaded_line_number',
        );
        eq_or_diff($po->msgid(),  "id $_",  'msgid');
        eq_or_diff($po->msgstr(), "str $_", 'msgstr');
    }
}

# drop table
SKIP: {
    skip('delete file', 1)
        if ! $DROP_TABLE;

    unlink $FILE_LOCALE_PO_02;
    ok(! -e $FILE_LOCALE_PO_02, 'table file deleted');
}