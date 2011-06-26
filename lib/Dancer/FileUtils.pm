package Dancer::FileUtils;
# ABSTRACT: common tools for file-system related actions
use strict;
use warnings;

use File::Basename ();
use File::Spec;
use Carp;
use Cwd 'realpath';

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(dirname open_file path read_file_content
                read_glob_content real_path set_file_mode);

=func catfile

Wrapper to L<File::Spec> catfile, with some cygwin magic.

=cut
sub catfile { File::Spec->catfile(_trim_UNC(@_)) }

=func catdir

Wrapper to L<File::Spec> catdir, with some cygwin magic.

=cut
sub catdir { File::Spec->catdir(_trim_UNC(@_)) }

=func canonpath

Wrapper to L<File::Spec> canonpath, with some cygwin magic.

=cut
sub canonpath { File::Spec->canonpath(_trim_UNC(@_)) }

=func catpath

Wrapper to L<File::Spec> catpath, with some cygwin magic.

=cut
sub catpath { File::Spec->catpath(_trim_UNC(@_)) }

=func splitpath

Wrapper to L<File::Spec> splitpath, with some cygwin magic.

=cut
sub splitpath { File::Spec->splitpath(_trim_UNC(@_)) }

=func path

    use Dancer::FileUtils 'path';

    my $path = path( 'folder', 'folder', 'filename');

Provides comfortable path resolving, internally using L<File::Spec>.

=cut
sub path { catfile(@_) }

=func real_path

    use Dancer::FileUtils 'real_path';

    my $real_path=real_path ($path);

Returns a canonical and absolute path. Uses Cwd's realpath internally which
resolves symbolic links and relative-path components ("." and ".."). If
specified path does not exist, real_path returns nothing.

=cut
sub real_path {
  my $path = catfile(@_);
  #If Cwd's realpath encounters a path which does not exist it returns
  #empty on linux, but croaks on windows.
  if (! -e $path) {
    return;
  }
  realpath($path);
}


=func path_no_verify

Same behavior as C<real_path>, but does not verify if the specified
path exists.

=cut
sub path_no_verify {
    my @nodes = File::Spec->splitpath(catdir(@_)); # 0=vol,1=dirs,2=file
    my $path = '';

    # [0->?] path(must exist),[last] file(maybe exists)
    if($nodes[1]) {
        $path = realpath(File::Spec->catpath(@nodes[0 .. 1],'')) . '/';
    } else {
        $path = Cwd::cwd . '/';
    }
    $path .= $nodes[2];
    return $path;
}

=func dirname

    use Dancer::FileUtils 'dirname';

    my $dir = dirname($path);

Exposes L<File::Basename>'s I<dirname>, to allow fetching a directory name from
a path. On most OS, returns all but last level of file path. See
L<File::Basename> for details.

=cut
sub dirname { File::Basename::dirname(@_) }

=func set_file_mode

    use Dancer::FileUtils 'set_file_mode';

    set_file_mode($fh);

Applies charset setting from Dancer's configuration. Defaults to utf-8 if no
charset setting.

=cut
sub set_file_mode {
    my ($fh) = @_;
    require Dancer::Config;
    my $charset = Dancer::Config::setting('charset') || 'utf-8';

    if($charset) {
        binmode($fh, ":encoding($charset)");
    }
    return $fh;
}

=func open_file

    use Dancer::FileUtils 'open_file';
    my $fh = open_file('<', $file) or die $message;

Calls open and returns a filehandle. Takes in account the 'charset' setting
from Dancer's configuration to open the file in the proper encoding (or
defaults to utf-8 if setting not present).

=cut
sub open_file {
    my ($mode, $filename) = @_;
    open(my $fh, $mode, $filename)
      or croak "$! while opening '$filename' using mode '$mode'";
    return set_file_mode($fh);
}

=func read_file_content

    use Dancer::FileUtils 'read_file_content';

    my @content = read_file_content($file);
    my $content = read_file_content($file);

Returns either the content of a file (whose filename is the input), I<undef>
if the file could not be opened.

In array context it returns each line (as defined by $/) as a seperate element;
in scalar context returns the entire contents of the file.

=cut
sub read_file_content {
    my ($file) = @_;
    my $fh;

    if ($file) {
        $fh = open_file('<', $file);

        return wantarray ? read_glob_content($fh) : scalar read_glob_content($fh);
    }
    else {
        return;
    }
}

=func read_glob_content

    use Dancer::FileUtils 'read_glob_content';

    open my $fh, '<', $file or die "$!\n";
    my @content = read_glob_content($fh);
    my $content = read_glob_content($fh);

Same as I<read_file_content>, only it accepts a file handle. Returns the
content and B<closes the file handle>.

=cut
sub read_glob_content {
    my ($fh) = @_;

    # we don't want to do that as we'll encode the stuff later
    # binmode $fh;

    my @content = <$fh>;
    close $fh;

    return wantarray ? @content : join("", @content);
}

# privates


# Undo UNC special-casing catfile-voodoo on cygwin
sub _trim_UNC {
    if ($^O eq 'cygwin') {
        return if ($#_ < 0);
        my ($slashes, $part, @parts) = (0, undef, @_);
        while(defined($part = shift(@parts))) { last if ($part); $slashes++ }
        $slashes += ($part =~ s/^[\/\\]+//);
        if ($slashes == 2) {
            return("/" . $part, @parts);
        } else {
            my $slashstr = '';
            $slashstr .= '/' for (1 .. $slashes);
            return($slashstr . $part, @parts);
        }
    }
    return(@_);
}



'Dancer::FileUtils';

__END__


=head1 SYNOPSIS

    use Dancer::FileUtils qw/dirname real_path/;

    # for 'path/to/file'
    my $dir=dirname ($path); #returns 'path/to'
    my $real_path=real_path ($path); #returns '/abs/path/to/file'


    use Dancer::FileUtils qw/path read_file_content/;

    my $content = read_file_content( path( 'folder', 'folder', 'file' ) );
    my @content = read_file_content( path( 'folder', 'folder', 'file' ) );


    use Dancer::FileUtils qw/read_glob_content set_file_mode/;

    open my $fh, '<', $file or die "$!\n";
    set_file_mode ($fh);
    my @content = read_file_content($fh);
    my $content = read_file_content($fh);


=head1 DESCRIPTION

Dancer::FileUtils includes a few file related utilities related that
Dancer uses internally. Developers may use it instead of writing their
own file reading subroutines or using additional modules.

=head1 EXPORT

Nothing by default. You can provide a list of subroutines to import.

=cut
