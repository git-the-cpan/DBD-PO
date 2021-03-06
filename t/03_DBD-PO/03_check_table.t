#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $SEPARATOR $EOL
    trace_file_name
    $TABLE_0X $FILE_0X
);
use Test::More tests => 8 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
}

my $dbh;

# connext
{
    $dbh = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_charset=utf-8",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        },
    );
    isa_ok($dbh, 'DBI::db', 'connect');

    if ($TRACE) {
        open my $file, '>', trace_file_name();
        $dbh->trace(4, $file);
    }
}

# check table
{
    my $sth = $dbh->prepare(<<"EO_SQL");
        SELECT msgid, msgstr
        FROM   $TABLE_0X
        WHERE  msgid=?
EO_SQL
    isa_ok($sth, 'DBI::st');

    my @data = (
        {
            id     => 'id_2',
            _id    => 'id_2',
            result => 1,
            fetch  => [
                {
                    msgid  => 'id_2',
                    msgstr => 'str_2',
                },
            ],
        },
        {
            id     => "id_value1${SEPARATOR}id_value2",
            _id    => "id_value1\${separator}id_value2",
            result => 1,
            fetch  => [
                {
                    msgid  => "id_value1${SEPARATOR}id_value2",
                    msgstr => "str_value1${SEPARATOR}str_value2",
                },
            ],
        },
    );

    for my $data (@data) {
        my $result = $sth->execute($data->{id});
        is($result, $data->{result}, "execute: $data->{_id}");

        $result = $sth->fetchall_arrayref( {} );
        is_deeply(
            $result,
            $data->{fetch},
            "fetch result: $data->{_id}",
        );
    }
}

# check table file
{
    my $po = <<'EOT';
# comment1
# comment2
msgid ""
msgstr ""
"Project-Id-Version: Testproject\n"
"Report-Msgid-Bugs-To: Bug Reporter <bug@example.org>\n"
"POT-Creation-Date: no POT creation date\n"
"PO-Revision-Date: no PO revision date\n"
"Last-Translator: Steffen Winkler <steffenw@example.org>\n"
"Language-Team: MyTeam <cpan@example.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: 8bit\n"
"X-Poedit-Language: German\n"
"X-Poedit-Country: GERMANY\n"
"X-Poedit-SourceCharset: utf-8"

# comment_value
#. automatic_value
#: ref_value
msgctxt "context_value"
msgid "id_value"
msgstr "str_value"

# comment_value1
# comment_value2
#. automatic_value1
#. automatic_value2
#: ref_value1
#: ref_value2
msgctxt ""
"context_value1\n"
"context_value2"
msgid ""
"id_value1\n"
"id_value2"
msgstr ""
"str_value1\n"
"str_value2"

msgid "id_value_mini"
msgstr ""

msgid "id_1"
msgstr "str_1"

msgid "id_2"
msgstr "str_2"

msgid "id_singular"
msgid_plural "id_plural"
msgstr[0] "str_singular"
msgstr[1] "str_plural"

msgid ""
"id_singular1\n"
"id_singular2"
msgid_plural ""
"id_plural1\n"
"id_plural2"
msgstr[0] ""
"str_singular1\n"
"str_singular2"
msgstr[1] ""
"str_plural1\n"
"str_plural2"

msgid "id_value_singular_mini"
msgid_plural "id_value_plural_mini"
msgstr[0] ""

EOT
    open my $file, '< :raw', $FILE_0X or croak $OS_ERROR;
    local $INPUT_RECORD_SEPARATOR = ();
    my $content = <$file>;
    $po =~ s{\n}{$EOL}xmsg;
    eq_or_diff($content, $po, 'check po file');
}