package App::TimeTracker::Schema::Tag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(ResultSetManager Core));
__PACKAGE__->table("tag");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "tag",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-18 19:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gV1nX6s7CnH07B6N9pwkWQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_many('task_tags' => 'App::TimeTracker::Schema::TaskTag', 'tag');
__PACKAGE__->many_to_many('tasks' => 'task_tags', 'task');

sub rest_list : ResultSet {
    my $self = shift;
    my $cond = shift;
    my $attrs = shift || {};

    my $list = $self->search( {}, { order_by => 'tag' } );
    my @list;
    while ( my $li = $list->next ) {
        push(@list,{
            tag      => $li->tag,
            _resource => '/rest/tag/'.$li->id,
        });
    }
    return \@list;
}

1;

__END__

=pod

=head1 NAME

App::TimeTracker::Schema::Tag

=head1 DESCRIPTION

DBIx::Class 

=cut

