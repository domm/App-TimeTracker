package App::TimeTracker::Schema::Task;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("task");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "project",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "active",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "start",
  { data_type => "date", is_nullable => 0, size => undef },
  "stop",
  { data_type => "date", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-18 19:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MOy38CnmqVCkh+yiSXSYww


# You can replace this text with custom content, and it will be 
# preserved on regeneration

__PACKAGE__->add_unique_constraint(active=>['active']);
__PACKAGE__->belongs_to(project=>'App::TimeTracker::Schema::Project');

__PACKAGE__->has_many('task_tags' => 'App::TimeTracker::Schema::TaskTag', 'task');
__PACKAGE__->many_to_many('tags' => 'task_tags', 'tag');


__PACKAGE__->inflate_column('start',
    {
        inflate=>sub {my $h=DateTime::Format::Strptime->new(pattern=>'%F %T');$h->parse_datetime(shift)},
        deflate=>sub {my $h=DateTime::Format::Strptime->new(pattern=>'%F %T');$h->format_datetime(shift)},
    }
);

__PACKAGE__->inflate_column('stop',
    {
        inflate=>sub {my $h=DateTime::Format::Strptime->new(pattern=>'%F %T');$h->parse_datetime(shift)},
        deflate=>sub {my $h=DateTime::Format::Strptime->new(pattern=>'%F %T');$h->format_datetime(shift)},
    }
);

1;

__END__

=pod

=head1 NAME

App::TimeTracker::Schema::Task

=head1 DESCRIPTION

DBIx::Class 

=cut

