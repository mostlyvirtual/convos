use Mojo::Base -strict;
use Test::More;
use Convos::Core;

my $core       = Convos::Core->new;
my $user       = $core->user('test@example.com', {});
my $connection = $user->connection(IRC => 'whatever', {});

isa_ok($connection->conversation('#foo'),   'Convos::Core::Conversation::Room');
isa_ok($connection->conversation('marcus'), 'Convos::Core::Conversation::Direct');
ok !$connection->{conversation}{'#foo'}, 'no conversation on get';

my $conversation = $connection->conversation('#foo' => {});
is $conversation->path, '/test@example.com/IRC/whatever/#foo', 'conversation->path';
is $conversation->n_users, 0, 'conversation->n_users';
ok $connection->{conversations}{'#foo'}, 'conversation on create/update';

$connection = Convos::Core::Connection->new;
for my $method (qw( rooms join_conversation connect send topic)) {
  my $err;
  eval {
    $connection->$method(sub { $err = $_[1] });
  };
  is $err, qq(Method "$method" not implemented.), $method;
}

done_testing;
