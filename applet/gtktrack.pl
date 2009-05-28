use 5.010;
use strict;
use warnings;
use Gtk2 -init;
use AnyEvent;
use App::TimeTracker;
use App::TimeTracker::Task;
use Gtk2::TrayIcon;
use FindBin qw($Bin);

my $storage_location = App::TimeTracker->storage_location;

my $window= Gtk2::TrayIcon->new("test");
my $eventbox = Gtk2::EventBox->new;
my $img= Gtk2::Image->new_from_file("$Bin/lazy.png");
$eventbox->add($img);

my $current;
my $t = AnyEvent->timer(after => 0, interval => 5, cb => sub {
    my $task = App::TimeTracker::Task->get_current($storage_location);
    if ($task) {
        $img->set_from_file("$Bin/busy.png");
        $current = $task->project.$task->nice_tags;
    }
    else {
        $img->set_from_file("$Bin/lazy.png");
        $current = 'nothing';
    }
});



$eventbox->signal_connect( 'enter-notify-event' => sub { 
    unless ($current eq 'nothing') {
    
        my $dialog = Gtk2::MessageDialog->new ($window,
            [qw/modal destroy-with-parent/],
            'other',
            'none',
            $current
        );
    
        $dialog->set_decorated (0);
        $dialog->set_gravity ('south-west');

        my $t = AnyEvent->timer(after => 5, cb => sub {
            $dialog->destroy;
        });			
        my $retval = $dialog->run;
        $dialog->destroy;
    }
});

$window->add($eventbox);
$window->show_all;


Gtk2->main;




__END__




my $vbox = Gtk2::VBox->new(undef,0);


my $menu_edit = Gtk2::Menu->new();

my $menu_item_toggle = Gtk2::MenuItem->new('sdf');
  		#connect to the toggled signal to catch the active state
#$menu_item_toggle->signal_connect('toggled' => \&toggle,"Toggle Menu Item");
$menu_edit->append($menu_item_toggle);

my $menu_bar = Gtk2::MenuBar->new;


my $menu_item_image = Gtk2::ImageMenuItem->new ('Image Menu Item');
my $img = Gtk2::Image->new_from_file('/home/domm/lazy.png');
#connet to the activate signal to catch when this item is selected
$menu_item_image->set_image($img);
  	


#my $menu_item_edit= Gtk2::MenuItem->new('x');
#$menu_item_edit->set_submenu ($menu_edit);
$menu_item_image->set_submenu ($menu_edit);



$menu_bar->append($menu_item_image);

$vbox->pack_start($menu_bar,undef,undef,0);
$vbox->show_all();


$window->add($vbox);
$window->show();


  Gtk2->main;

__END__

my $icon= Gtk2::TrayIcon->new("test");
 my $bubble;

my $eventbox = Gtk2::EventBox->new;
my $img= Gtk2::Image->new_from_file("/home/domm/lazy.png");
$eventbox->add($img);

    $eventbox->signal_connect(
         'enter-notify-event' => sub { 
             #Remove the toggle action
             #Glib::Source->remove ($event_number);
             $bubble->set(
                 'Sorry...',     #Heading
                 undef,          #icon (Gtk2::Image)
                 'For being so persistent ;-)',  #message
             );
             $bubble->show(0); #to keep it forever set it to < 0
         }
     );

 $icon->add($eventbox);
 $icon->show_all;


  Gtk2->main;


__END__

#my $window = Gtk2::TrayIcon->new("TimeTracker");
#$window->signal_connect(destroy => sub { Gtk2->main_quit; });
#$window->add(Gtk2::Image->new_from_file('/home/domm/lazy.png'));

my $menu = Gtk2::Menu->new;
#my $menuitem = Gtk2::MenuItem->new_with_label ("foo");
     # $menu->append ($menuitem);
     #       $menuitem->show;

     my $box1 = Gtk2::VBox->new (undef, 0);
      $window->add ($box1);
$box1->show;
      
      $box1->pack_start ($menu,1,1,1);
      $menu->show;


#$icon->add($label);
  $window->show_all;
  
  Gtk2->main;



__END__


my $window = Gtk2::Window->new ('toplevel');
$window->set_border_width(6);
$window->set_size_request(150, 150);
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

#$window->set_decorated(0);
#$window->set_type_hint('desktop');

my $red = Gtk2::Gdk::Color->new (257,0,0);

my $text = Gtk2::TextView->new;
$text->set_wrap_mode('word-char');
$text->set_cursor_visible(0);
my $buffer = $text->get_buffer;
my $t = AnyEvent->timer(after => 0, interval => 15, cb => sub {
    my $current = App::TimeTracker::Task->get_current(App::TimeTracker->storage_location);
    my $string = $current ? $current->project.$current->nice_tags : 'nothing';
    $buffer->set_text($string);
    $window->set_title($string);
});

$text->set_editable(0);
$window->add ($text);
$window->show_all;
Gtk2->main;



