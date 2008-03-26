package MT::Plugin::OMV::RecentSearchStrings;

use MT::Log;

use MT::Template::Context;
MT::Template::Context->add_container_tag( RecentSearchStrings => \&_hdlr_recent_search_strings );
sub _hdlr_recent_search_strings {
    my( $ctx, $args, $cond ) = @_;

    # Regular expression pattern
    $mt = MT->instance;
    my $re = $mt->translate("Search: query for '[_1]'", '(.+)');
    $re = qr/$re/;

    # Parameters
    my $lastn = $args->{lastn} || 999999;

    # Retrieve logs
    my $iter = MT::Log->load_iter({
        class => 'search', category => 'straight_search',
    }) or return '';

    my %search_word = ();
    while( defined( my $log = $iter->()) && scalar keys %search_word < $lastn ) {
        my( $query_string ) = $log->message =~ /$re/
            or next;
        $search_word{$query_string}++;
    }

    # Build templates
    my @output = ();
    my $build = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    foreach( keys %search_word ) {
        local $ctx->{__stash}->{search_string} = $_;
        defined( my $out = $build->build( $ctx, $tokens, %cond ))
            or return $ctx->error( $build->errstr );
        push @output, $out;
    }
    join $args->{glue} || '' , @output;
}

MT::Template::Context->add_tag( SearchString => sub { $_[0]->stash('search_string') || '' });

1;