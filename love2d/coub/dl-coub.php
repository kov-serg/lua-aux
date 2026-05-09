<?php

$url="https://coub.com/view/2m7y4c";
// $url="https://coub.com/view/11mwfl";
// $url="https://coub.com/view/26d2c0";
// $url="https://coub.com/view/49ubt8";
// $url="https://coub.com/view/4aq830";
// $url="https://coub.com/view/4as4t3";
// $url="https://coub.com/view/4as96v";
// $url="https://coub.com/view/4atq5r";

if ($argc>1) $url=$argv[1]; // else die;

function download($url) {
    //return file_get_contents($url);
    $proxy=false; // '127.0.0.1:1080';
    $limit=5;
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    if ($proxy) {
        curl_setopt($ch, CURLOPT_PROXY, $proxy); // Set the proxy address
        curl_setopt($ch, CURLOPT_PROXYTYPE,CURLPROXY_SOCKS5); // Specify SOCKS5 type
    }
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
    $userAgent = 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:149.0) Gecko/20100101 Firefox/149.0';
    curl_setopt($ch, CURLOPT_USERAGENT, $userAgent);
    // $proxy_userpwd = 'username:password';
    // curl_setopt($ch, CURLOPT_PROXYUSERPWD, $proxy_userpwd);
    for(;;) {
        $res=curl_exec($ch);
        $err=curl_errno($ch);
        if (!$err) break;
        fprintf(STDERR,"Error(%d): %s\n",$err,curl_error($ch));
        if ($err!=97) break;
        $limit--; if ($limit<0) return null;
        fprintf(STDERR,"Repeat downloading %s\n",$url);
    }
    curl_close($ch);
    // printf("res size=%d\n",strlen($res));
    return $res;
}

function get($name,$url) {
    if (file_exists($name)) return file_get_contents($name);
    //$data=file_get_contents($url);
    $data=download($url);
    if (!$data) die("unable to get $url\n");
    file_put_contents($name,$data);
    return $data;
}
function load($name,$url) {
    if (file_exists($name)) return true;
    //$data=file_get_contents($url);
    $data=download($url);
    if (!$data) return false;
    file_put_contents($name,$data);
    return true;
}

$data=get("coub.html",$url);
$json="";
if (preg_match("#<script id='coubPageCoubJson' type='text/json'>#i",$data,$m,PREG_OFFSET_CAPTURE)) {
   $p1=$m[0][1]+strlen($m[0][0]);
   if (preg_match("#</script>#i",$data,$m,PREG_OFFSET_CAPTURE,$p1)) {
      $p2=$m[0][1];
      $json=substr($data,$p1,$p2-$p1);
   }
} else {
    rename("coub.html","coub.txt");
    die('not found');
}
$data=json_decode($json);
//print_r($data);

$id=$data->id;
$link=$data->permalink;
$html5=$data->file_versions->html5;
$url_video=$html5->video->high->url;
$url_audio=$html5->audio->high->url;
// $url_video=$html5->video->med->url;
// $url_audio=$html5->audio->med->url;
$title=$data->title;
$title_tr=$data->translated_title;
$aurl=$data->audio_file_url;
$dir="coub"; if (preg_match("/[a-z0-9-_]+/i",$link,$m)) $dir=$m[0];
@mkdir($dir);
file_put_contents("$dir/main.lua",<<<"LUA_CODE"
if not love then os.execute 'love .' os.exit() end
local gr=love.graphics
love.window.setTitle[[$title]]
local w,h,m=love.window.getMode()
m.resizable=true
love.window.setMode(w,h,m)

local Coub={}

function Coub:load(vfn,afn)
    self.video=love.graphics.newVideo(vfn)
    self.audio=love.audio.newSource(afn,"stream")
    self.audio:setLooping(true)
    self.w, self.h = self.video:getDimensions()
    self.x,self.y=0,0
    self.kx,self.ky=1,1
    self.r=0
    self.paused=false
    return self
end
function Coub:play() self.video:play() self.audio:play() self.paused=false return self end
function Coub:pause() self.video:pause() self.audio:pause() self.paused=true return self end
function Coub:tougle_play() if self.paused then self:play() else self:pause() end return self end
function Coub:rewind() self.video:rewind() self.audio:rewind() return self end
function Coub:isPlaying() return self.video:isPlaying() end
function Coub:draw(gr,x,y)
    gr.draw(self.video,x or self.x,y or self.y,self.r,self.kx,self.ky)
end
function Coub:check_playing()
    if not self.paused and not self:isPlaying() then self.video:rewind() end
end
function Coub:place_optimal(gr)
    local w,h=gr:getDimensions()
    local k=math.min(w/self.w,h/self.h)
    local kw,kh=k*self.w, k*self.h
    self.kx, self.ky = k, k
    self.x,  self.y  = (w-kw)/2, (h-kh)/2
end
function Coub.new(name)
    local self=setmetatable({},{__index=Coub})
    if type(name)=='string' then self:load(name..".ogv",name..".mp3") end
    return self
end

local app={}

function love.load()
    gr.setFont(gr.newFont(20))
    app.coub=Coub.new("coub"):play()
    love.keypressed "f11"
end

function love.keypressed(key,scan,rep)
    if key=='escape' then love.event.quit() end
    if key=='space' then app.coub:tougle_play() end
    if key=='f11' then
        local fs=not love.window.getFullscreen()
        love.mouse.setVisible(not fs)
        love.window.setFullscreen(fs)
    end
end

function love.draw()
    gr.setColor{1,1,1}
    app.coub:place_optimal(gr)
    app.coub:check_playing()
    app.coub:draw(gr)
end
LUA_CODE
);

load("coub.mp4",$url_video);
load("$dir/coub.mp3",$url_audio);
print("$link $id $title\n");
if (!file_exists("$dir/coub.ogv")) {
    exec("ffmpeg -y -loglevel warning -hide_banner -stats -i coub.mp4 -c:v libtheora -q:v 6 -an $dir/coub.ogv");
}
exec("cd $dir ; 7z a -tzip ../coub-$dir.lovegame . ; cd ..");
unlink("coub.mp4");
unlink("coub.html");
