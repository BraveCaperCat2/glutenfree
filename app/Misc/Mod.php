<?php

namespace App\Misc;

use vierbergenlars\SemVer\Internal\SemVer;

class Mod
{
    public string $name;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function source()
    {
        return __GLUTENFREE__ . '/mods/' . $this->name;
    }

    public function version()
    {
        return json_decode(file_get_contents("{$this->source()}/info.json"), true)['version'];
    }

    public function setVersion(string $version)
    {
        $json = json_decode(file_get_contents("{$this->source()}/info.json"), true);
        $json['version'] = $version;
        file_put_contents("{$this->source()}/info.json", json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }

    public function zip_name_without_extension()
    {
        return "{$this->name}_{$this->version()}";
    }

    public function build()
    {
        $source = __GLUTENFREE__ . '/mods/' . $this->name;
        $dest = __GLUTENFREE__ . '/build/' . $this->zip_name_without_extension();

        passthru(sprintf("rsync -avr --delete %s/ %s", $source, $dest));
        passthru(sprintf("(cd %s && zip -FSr %s %s)", __GLUTENFREE__ . '/build/', "{$dest}.zip", $this->zip_name_without_extension()));
    }

    public function sha1()
    {
        return sha1_file(__GLUTENFREE__ . '/build/' . $this->zip_name_without_extension() . '.zip');
    }
}