package TimeTracker::Schema::TaskTag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("task_tag");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "task",
  { data_type => "integer", is_nullable => 0, size => undef },
  "tag",
  { data_type => "integer", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2008-01-18 19:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MQpQLIoKnhMhoCThVdNdeQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->belongs_to('task' => 'TimeTracker::Schema::Task');
__PACKAGE__->belongs_to('tag' => 'TimeTracker::Schema::Tag');


1;
