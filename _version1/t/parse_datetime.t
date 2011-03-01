
use Test::More tests => 14;
use Test::NoWarnings;
use App::TimeTracker;

my $t=App::TimeTracker->new;

{
    my $d=$t->parse_datetime("1005");
    isa_ok($d,'DateTime');
    is($d->hour(),10,'1005 hour');
    is($d->minute(),05,'1005 min');
}

{
    my $d=$t->parse_datetime("0226-1345");
    isa_ok($d,'DateTime');
    is($d->day(),26,'0226 1345 hour');
    is($d->month(),2,'0226 1345 hour');
    is($d->hour(),13,'0226 1345 hour');
    is($d->minute(),45,'0226 1345 min');
}

{
    my $d=$t->parse_datetime("0226_1345");
    isa_ok($d,'DateTime');
    is($d->day(),26,'0226 1345 hour');
    is($d->month(),2,'0226 1345 hour');
    is($d->hour(),13,'0226 1345 hour');
    is($d->minute(),45,'0226 1345 min');
}


