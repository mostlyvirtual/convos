#!perl
use lib '.';
use t::Helper;

$ENV{CONVOS_CMS_PERLDOC} = 1;
$ENV{MOJO_MODE}          = 'production';
my $t       = t::Helper->t;
my $cms_dir = $t->app->core->home->child('content');

subtest 'bundled doc' => sub {
  $t->get_ok('/doc/nope')->status_is(404)->element_exists('h1')->text_is('h1', 'Not Found (404)');
  $t->get_ok('/doc/Convos/Core')->status_is(200)->header_is('X-Provider-Name', undef)
    ->element_exists(
    'meta[name="description"][content="Convos::Core is the heart of the Convos backend."]')
    ->element_exists(qq(meta[name="convos:start_app"][content=""]))
    ->text_is('.toc li a[href="#description"]', 'DESCRIPTION')
    ->text_is('title',                          'Convos::Core - Convos backend - Convos')
    ->text_is('h1.cms-header',                  'Convos::Core - Convos backend');
};

subtest 'default index file' => sub {
  $t->get_ok('/')->status_is(200)->header_is('X-Provider-Name', 'ConvosApp')
    ->element_exists(qq(meta[name="convos:start_app"][content="chat"]))->element_exists('.hero');
};

subtest 'custom index file' => sub {
  $cms_dir->make_path;
  $cms_dir->child('index.md')->spew("# Custom index\n\nToo cool for school!\n");
  $t->get_ok('/')->status_is(200)->header_is('X-Provider-Name', undef)
    ->element_exists(qq(meta[name="convos:start_app"][content=""]))->element_exists('body.for-cms')
    ->element_exists('body.for-cms > article')->text_is('title', 'Custom index - Convos')
    ->text_is('h1', 'Custom index')
    ->text_like('body.for-cms > article > p', qr{Too cool for school});
};

subtest 'empty blog index' => sub {
  $t->get_ok('/blog')->status_is(200)->element_exists('body.for-cms')
    ->element_exists('body.for-cms > main')->text_like('main > p', qr{is empty});
};

subtest 'blog too-cool' => sub {
  my $code = <<'HERE';
        #!/usr/bin/env perl
        use Mojo::Base -strict;

        # Avoid double line breaks above this comment
        exit;
HERE

  $t->get_ok('/blog/2020/5/17/too-cool.html')->status_is(404);
  $cms_dir->child(qw(blog 2020))->make_path;
  $cms_dir->child(qw(blog 2020 2020-05-17-too-cool.md))->spew(<<"HERE");
---
title: Cool title
author: Jan Henning Thorsen
heading: Cool heading
toc: true
---
## Cool sub title
This blog is about
some cool stuff.

## Cool other title
And then some!

<div markdown>
  ### Another heading
  And a paragraph.
  ![fab](github)
  ![fas](eye)

      code inside

</div>

1. some list item
2. another list with code

$code

<div class="is-before-content">Is before content.</div>
<div class="is-after-content">Is after content.</div>
<style>
body {
  background: red;
}
</style>
HERE

  $code =~ s!^        !!mg;
  chomp $code;

  $t->get_ok('/blog/2020/5/17/too-cool.html')->status_is(200)->header_is('X-Provider-Name', undef)
    ->element_exists('body.for-cms > article')->text_is('title', 'Cool title - Convos')
    ->element_exists('meta[name="description"][content="This blog is about some cool stuff."]')
    ->element_exists(qq(meta[name="convos:start_app"][content=""]))->text_is('h1', 'Cool heading')
    ->element_exists('body.for-cms')
    ->text_like('body.for-cms > article > p', qr{This blog is about.*some cool stuff}s)
    ->text_is('.toc li a[href="#cool-sub-title"]',     'Cool sub title')
    ->text_is('.toc li li a[href="#another-heading"]', 'Another heading')
    ->text_like('head > style', qr{background: red})->text_unlike('head > style', qr{<p>})
    ->text_is('body > .is-before-content',                            'Is before content.')
    ->text_is('body > .is-after-content',                             'Is after content.')
    ->text_is('body > article > ol:nth-of-type(2) li:last-child pre', $code)
    ->text_is('[markdown] h3',  'Another heading')->text_like('[markdown] p', qr{And a paragraph})
    ->text_is('[markdown] pre', 'code inside')->element_exists('[markdown] i[class="fas fa-eye"]')
    ->element_exists('[markdown] i[class="fab fa-github"]')->element_exists_not('attr');
};

subtest 'blog index' => sub {
  $t->get_ok('/blog')->status_is(200)->header_is('X-Provider-Name', undef)->element_exists('main')
    ->element_exists('main section.blog-list__item')->text_is('section h2', 'Cool heading')
    ->text_is('section .cms-meta .cms-meta__author', 'Posted by Jan Henning Thorsen')
    ->text_is('section .cms-meta .cms-meta__date',   '17. May, 2020')
    ->text_like('section .cms-excerpt', qr{This blog is about.*some cool stuff.}s)
    ->text_is('section .cms-more a', 'Read more');
};

subtest 'txt' => sub {
  $t->get_ok('/.txt')->status_is(200)->content_like(qr{^\# Custom index}s);
  $t->get_ok('/blog.txt')->status_is(200)->content_like(qr{^\# Blog.*\#\# Cool heading}s);
  $t->get_ok('/blog/2020/5/17/too-cool.txt')->status_is(200)->content_like(qr{^\# Cool heading}s);
  $t->get_ok('/doc/Convos.txt')->status_is(200)->content_like(qr{^package Convos;});
};

subtest 'yaml' => sub {
  $t->get_ok('/.yaml')->status_is(200)->content_like(qr{^---.*body:}s);
  $t->get_ok('/blog.yaml')->status_is(200)->content_like(qr{^---.*blogs:}s);
  $t->get_ok('/blog/2020/5/17/too-cool.yaml')->status_is(200)->content_like(qr{^---.*body:}s);
  $t->get_ok('/doc/Convos.yaml')->status_is(200)->content_like(qr{^---.*body:}s);
};

done_testing;
