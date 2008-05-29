package App::TimeTracker::Schema::Project;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(ResultSetManager Core));
__PACKAGE__->table("project");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "name",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-18 19:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8VdS/C1LEada8y8QaKhMug


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_many('tasks','App::TimeTracker::Schema::Task','project');
__PACKAGE__->add_unique_constraint(name=>['name']);

sub rest_list : ResultSet {
    my $self = shift;
    my $cond = shift;
    my $attrs = shift || {};

    my $list = $self->search( {}, { order_by => 'name' } );
    my @list;
    while ( my $li = $list->next ) {
        push(@list,{
            name      => $li->name,
            _resource => '/rest/project/'.$li->id,
        });
    }
    return \@list;
}

1;
__END__

=pod

=head1 NAME

App::TimeTracker::Schema::Project

=head1 DESCRIPTION

DBIx::Class 

=cut


