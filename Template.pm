### //////////////////////////////////////////////////////////////////////////
#
#	TOP
#

=head1 NAME

DynaPage::Template - Dynamic Page document content

 #------------------------------------------------------
 # (C) Daniel Peder & Infoset s.r.o., all rights reserved
 # http://www.infoset.com, Daniel.Peder@infoset.com
 #------------------------------------------------------

=cut

###													###
###	size of <TAB> in this document is 4 characters	###
###													###

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: package
#

    package DynaPage::Template;


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: version
#

	use vars qw( $VERSION $VERSION_LABEL $REVISION $REVISION_DATETIME $REVISION_LABEL $PROG_LABEL );

	$VERSION           = '0.90';
	
	$REVISION          = (qw$Revision: 1.3 $)[1];
	$REVISION_DATETIME = join(' ',(qw$Date: 2005/01/13 21:31:07 $)[1,2]);
	$REVISION_LABEL    = '$Id: Template.pm,v 1.3 2005/01/13 21:31:07 root Exp root $';
	$VERSION_LABEL     = "$VERSION (rev. $REVISION $REVISION_DATETIME)";
	$PROG_LABEL        = __PACKAGE__." - ver. $VERSION_LABEL";

=pod

 $Revision: 1.3 $
 $Date: 2005/01/13 21:31:07 $

=cut


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: debug
#

	use vars qw( $DEBUG ); $DEBUG=0;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: constants
#

	# use constant	name		=> 'value';
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: modules use
#

	require 5.005_62;

	use strict                  ;
	use warnings                ;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: class properties
#

#	our	$config	= 
#	{
#	};
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: methods
#

=head1 METHODS

=over 4

=cut



### ##########################################################################

=item	new ( [ $template ] , [ $objectSourcer ] ) : DynaPage::Template::

=cut

### --------------------------------------------------------------------------
sub		new
### --------------------------------------------------------------------------
{
	my( $proto, $template, $objectSourcer ) = @_;
	
	my	$self  = {};
		bless( $self, (ref( $proto ) || $proto ));
		$self->template( $template ) if defined $template;
		$self->Sourcer( $objectSourcer ) if defined $objectSourcer;
	
	$self
}

### ##########################################################################

=item	Sourcer ( blessed ) : blessed

Set/Get the Sourcer object. Used to retrieve (Get) feedable values.
Sourcer must provide B<Get($name)> method.

=cut

### --------------------------------------------------------------------------
sub		Sourcer
### --------------------------------------------------------------------------
{
	my( $self, $Sourcer ) = @_;
    $self->{SOURCER} = $Sourcer if defined $Sourcer;
    $self->{SOURCER}
}


### ##########################################################################

=item	template ( $template ) : string

Set/Get the template's source.

=cut

### --------------------------------------------------------------------------
sub		template
### --------------------------------------------------------------------------
{
	my( $self, $template ) = @_;
    $self->{TEMPLATE} = $template if defined $template;
    $self->{TEMPLATE}
}


### ##########################################################################

=item	result ( $result ) : string

Set/Get the template's result string.

Internaly used to set it, however, externaly should be used 
to GET it ONLY.

=cut

### --------------------------------------------------------------------------
sub		result
### --------------------------------------------------------------------------
{
	my( $self, $result ) = @_;
    $self->{RESULT} = $result if defined $result;
    $self->{RESULT}
}


### ##########################################################################

=item	Feed ( [ $Sourcer ] , [$keep_unfilled_tags] ) : string

Feed the whole template. Unless $keep_unfilled_tags is specified,
unfilled tags are cleared after last iteration. Current limit is 10 iterations.

Specifying B< $Sourcer > forces another data source. See DynaPage::Sourcer .

=cut

### --------------------------------------------------------------------------
sub		Feed
### --------------------------------------------------------------------------
{
	my( $self, $Sourcer, $keep_unfilled_tags ) = @_;
	
		$self->Sourcer( $Sourcer ) or die "missing Sourcer object to provide tag values.";
	
	my	$maxCount	= 10;
	my(	$tags, $repl );
	do {
	do {
		
		( $tags, $repl ) = $self->feedTags();

	} while $tags && $repl && --$maxCount;
	} while !$keep_unfilled_tags && $self->clearTags();
	
	# variant: clear once at end
	# $self->clearTags() unless $keep_unfilled_tags;
	
	$self->result
}

### ##########################################################################

=item	feedTags ( ) : bool

Find and replace value tags. There are two tag types.
substituting raw values [~TagName~] or [X]HTML parameter safe values [!TagName!].

Parameter safe values means substituted entities: &quot; &lt; &gt; and &#39;

=cut

### --------------------------------------------------------------------------
sub		feedTags
### --------------------------------------------------------------------------
{
	my( $self ) = @_;
	
	my	$regex	= qr{\[([~!])([\w\-\.]+)\1\]}s; # same as clearTags
	my	$body	= $self->result() || $self->template();
	my	$tagsCount	= 0;
	my	$replCount	= 0;

    while( $body =~ m{$regex}cgos )
    {
    		$tagsCount++;
    	my	$matchLength	= length( $& );
    	my	$matchPos		= pos( $body ) - $matchLength;
    	my	$tagType	= $1;
    	my	$tagName	= $2; 
    	my	$parameterSafe	= ($tagType eq '!');
    	my	$tagValue	= $self->getTagValue( $tagName, $parameterSafe );
			next unless defined $tagValue;
			$replCount++;
	        substr( $body, $matchPos, $matchLength ) = $tagValue;
    	    pos( $body ) = $matchPos + length( $tagValue );
    }
	$self->result( $body );

	return $tagsCount, $replCount;
}


### ##########################################################################

=item	clearTags ( $clear_value ) : bool

Clear unfilled tags, resp. fill it with B< $clear_value >, which is by default
set to '';

Return B<TRUE> if some tags were cleared. Otherwise return B<FALSE>.

=cut

### --------------------------------------------------------------------------
sub		clearTags
### --------------------------------------------------------------------------
{
	my( $self, $clear_value ) = @_;

	my	$regex	= qr{\[([~!])([\w\-\.]+)\1\]}s; # same as feedTags
	my	$body	= $self->result() || $self->template();
	my  $status = 0;
	if( defined $clear_value ) {
        $status = scalar( $body =~ s/$regex/$clear_value/gs );
    }
    else {
        $status = scalar( $body =~ s/$regex//gs );
    }
	$self->result( $body );

    return $status;
}

### ##########################################################################

=item	getTagValue ( $name [, $parameterSafe ] ) : string

Get value of tag B<$name>. The value will be 
escaped to be B<$parameterSafe>.

=cut

### --------------------------------------------------------------------------
sub		getTagValue
### --------------------------------------------------------------------------
{
	my( $self, $name, $parameterSafe ) = @_;
	
	my	$value = $self->Sourcer->Get( $name );
	
	if( defined $value && $parameterSafe )
	{
		$value	=~ s{'}{&#39;}gos;
		$value	=~ s{"}{&quot;}gos;
		$value	=~ s{<}{&lt;}gos;
		$value	=~ s{>}{&gt;}gos;
	}

	return $value
}

=back

=cut


1;

__DATA__

__END__

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: TODO
#


=head1 TODO	


=cut
