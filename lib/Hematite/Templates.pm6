use Template::Mustache;
use Hematite::Exceptions;

unit class Hematite::Templates does Callable;

has Str $.directory;
has %!cache  = ();

submethod BUILD(Str :$directory) {
    $!directory = $directory || $*CWD ~ '/templates';

    return self;
}

method render-string(Str $template, :%data = {}, *%args) {
    return Template::Mustache.render(
        $template,
        %data.clone,
        from => [self.directory]
    );
}

method render-template(Str $name, :%data = {}, *%args) {
    # check in cache
    my $template = %!cache{$name};
    if (!$template) {
        # build full template file path and check if exists
        my $filepath = "{ self.directory }/{ $name }";
        if (!$filepath.IO.extension) {
            # if no extension, by default use 'html'
            $filepath ~= '.html';
        }

        # if file doesn't exists, throw error
        $filepath = $filepath.IO;
        if (!$filepath.e) {
            X::Hematite::TemplateNotFoundException.new(
                path => $filepath.Str).throw;
        }

        $template = $filepath.slurp;
        %!cache{$name} = $template;
    }

    return self.render-string($template, data => %data, |%args);
}

# render($template-name) ; render($template-string, inline => True)
method render(Str $data, *%args) {
    if (%args{'inline'}) {
        return self.render-string($data, |%args);
    }

    return self.render-template($data, |%args);
}

method CALL-ME($data, |args) {
    return self.render($data, |%(args));
}