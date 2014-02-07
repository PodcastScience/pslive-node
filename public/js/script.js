
/*
 * Audioplayer AUTHOR: Osvaldas Valutis, www.osvaldas.info
 */
(function(e,t,n,r){var i="ontouchstart"in t,s=i?"touchstart":"mousedown",o=i?"touchmove":"mousemove",u=i?"touchend":"mouseup",a=i?"touchcancel":"mouseup",f=function(e){var t=Math.floor(e/3600),n=Math.floor(e%3600/60),r=Math.ceil(e%3600%60);return(t==0?"":t>0&&t.toString().length<2?"0"+t+":":t+":")+(n.toString().length<2?"0"+n:n)+":"+(r.toString().length<2?"0"+r:r)},l=function(e){var t=n.createElement("audio");return!!(t.canPlayType&&t.canPlayType("audio/"+e.split(".").pop().toLowerCase()+";").replace(/no/,""))};e.fn.audioPlayer=function(t){var t=e.extend({classPrefix:"audioplayer",strPlay:"Play",strPause:"Pause",strVolume:"Volume"},t),n={},r={playPause:"playpause",playing:"playing",time:"time",timeCurrent:"time-current",timeDuration:"time-duration",bar:"bar",barLoaded:"bar-loaded",barPlayed:"bar-played",volume:"volume",volumeButton:"volume-button",volumeAdjust:"volume-adjust",noVolume:"novolume",mute:"mute",mini:"mini"};for(var u in r)n[u]=t.classPrefix+"-"+r[u];this.each(function(){if(e(this).prop("tagName").toLowerCase()!="audio")return false;var r=e(this),u=r.attr("src"),c=r.get(0).getAttribute("autoplay"),c=c===""||c==="autoplay"?true:false,h=r.get(0).getAttribute("loop"),h=h===""||h==="loop"?true:false,p=false;if(typeof u==="undefined"){r.find("source").each(function(){u=e(this).attr("src");if(typeof u!=="undefined"&&l(u)){p=true;return false}})}else if(l(u))p=true;var d=e('<div class="'+t.classPrefix+'">'+(p?e("<div>").append(r.eq(0).clone()).html():'<embed src="'+u+'" width="0" height="0" volume="100" autostart="'+c.toString()+'" loop="'+h.toString()+'" />')+'<div class="'+n.playPause+'" title="'+t.strPlay+'"><a href="#">'+t.strPlay+"</a></div></div>"),v=p?d.find("audio"):d.find("embed"),v=v.get(0);if(p){d.find("audio").css({width:0,height:0,visibility:"hidden"});d.append('<div class="'+n.time+" "+n.timeCurrent+'"></div><div class="'+n.bar+'"><div class="'+n.barLoaded+'"></div><div class="'+n.barPlayed+'"></div></div><div class="'+n.time+" "+n.timeDuration+'"></div><div class="'+n.volume+'"><div class="'+n.volumeButton+'" title="'+t.strVolume+'"><a href="#">'+t.strVolume+'</a></div><div class="'+n.volumeAdjust+'"><div><div></div></div></div></div>');var m=d.find("."+n.bar),g=d.find("."+n.barPlayed),y=d.find("."+n.barLoaded),b=d.find("."+n.timeCurrent),w=d.find("."+n.timeDuration),E=d.find("."+n.volumeButton),S=d.find("."+n.volumeAdjust+" > div"),x=0,T=function(e){theRealEvent=i?e.originalEvent.touches[0]:e;v.currentTime=Math.round(v.duration*(theRealEvent.pageX-m.offset().left)/m.width())},N=function(e){theRealEvent=i?e.originalEvent.touches[0]:e;v.volume=Math.abs((theRealEvent.pageY-(S.offset().top+S.height()))/S.height())},C=setInterval(function(){y.width(v.buffered.end(0)/v.duration*100+"%");if(v.buffered.end(0)>=v.duration)clearInterval(C)},100);var k=v.volume,L=v.volume=.111;if(Math.round(v.volume*1e3)/1e3==L)v.volume=k;else d.addClass(n.noVolume);w.html("â€¦");b.text(f(0));v.addEventListener("loadeddata",function(){w.text(f(v.duration));S.find("div").height(v.volume*100+"%");x=v.volume});v.addEventListener("timeupdate",function(){b.text(f(v.currentTime));g.width(v.currentTime/v.duration*100+"%")});v.addEventListener("volumechange",function(){S.find("div").height(v.volume*100+"%");if(v.volume>0&&d.hasClass(n.mute))d.removeClass(n.mute);if(v.volume<=0&&!d.hasClass(n.mute))d.addClass(n.mute)});v.addEventListener("ended",function(){d.removeClass(n.playing)});m.on(s,function(e){T(e);m.on(o,function(e){T(e)})}).on(a,function(){m.unbind(o)});E.on("click",function(){if(d.hasClass(n.mute)){d.removeClass(n.mute);v.volume=x}else{d.addClass(n.mute);x=v.volume;v.volume=0}return false});S.on(s,function(e){N(e);S.on(o,function(e){N(e)})}).on(a,function(){S.unbind(o)})}else d.addClass(n.mini);if(c)d.addClass(n.playing);d.find("."+n.playPause).on("click",function(){if(d.hasClass(n.playing)){e(this).attr("title",t.strPlay).find("a").html(t.strPlay);d.removeClass(n.playing);p?v.pause():v.Stop()}else{e(this).attr("title",t.strPause).find("a").html(t.strPause);d.addClass(n.playing);p?v.play():v.Play()}return false});r.replaceWith(d)});return this}})(jQuery,window,document)

/*
 * Scripts
 */

$(document).ready(function() {
	// C'est ready ! GO
	
	// Garde à vous !
	$chatroom = $('.chatroom');
	$header = $('header');
	$content = $('.content');
	$aside = $('.aside');
	$write = $('.write');
	$online = $('.online');
	
	// auto height
	function autoHeight() {
		// Tu mesures combien ?
		h_win = $(window).height();
		w_win = $(window).width();
		h_header = $header.outerHeight(); 
		w_content = $content.width();
		m_content = ( w_win - w_content ) / 2;
		h_content = h_win - h_header;
		w_aside = $aside.outerWidth();
		w_chatroom = $chatroom.outerWidth();
		h_write = $write.outerHeight();

		
		// header position fixed
		$header.css({
			'position' : 'fixed',
			'top' : '0',
			'left' : '0',
			'right' : '0',
			'z-index' : '9999'
		});
		$content.css('padding-top', h_header);
		
		// Layout col
		if ( w_win <= 1200 ) {
			var for100_w_chatroom = 40; //%
			var for100_w_write = 36; //%
		} else {
			var for100_w_chatroom = 32.89830508474576; //%
			var for100_w_write = 28.89830508474576; //%
			
			var styles_online = {
				'position' : 'fixed',
				'top' : h_header,
				'left' : (w_aside+m_content+w_chatroom),
				'width' : ( 13.94915254237288*w_content/100 ),
				'bottom' : '0',
				'padding-left' : (2*w_content/100), // 2%
				'padding-right' : (2*w_content/100), // 2%
				'overflow-y' : 'auto'
			}
			$online.css(styles_online);
		}
		
		var styles_write = {
			'position' : 'fixed',
			'left' : (w_aside+m_content),
			'width' : (for100_w_write*w_content/100 ),
			'padding-left' : (2*w_content/100), // 2%
			'padding-right' : (2*w_content/100), // 2%
			'bottom' : '0',
			'height' : '3em'
		};
		$write.css(styles_write);
		
		var styles_chatroom = {
			'position' : 'fixed',
			'top' : h_header,
			'left' : (w_aside+m_content),
			'width' : (for100_w_chatroom*w_content/100 ),
			'height' : h_win-h_header-$write.outerHeight(),
			'padding' : '0',
			'overflow-y' : 'auto'
		};
		$chatroom.css(styles_chatroom);
		
		var styles_messages = {
			'position' : 'absolute',
			'left' : '0',
			'right' : '0',
			'padding-left' : (3*w_content/100), // 3%
			'padding-right' : (4*w_content/100), // 4%
		}
		$('#messages').css(styles_messages);
		
		//var styles_wrap_messages = {
		//}
		//$('#messages', $chatroom).css(styles_wrap_messages);
		

		
		
		// height sharypic
		h_sharypic = w_aside*3/4;
		$('#live-draw-frame  > iframe').css('height', h_sharypic);
	
	}
	
	function resetAutoHeight() {
		$header.removeAttr('style');
		$content.removeAttr('style');
		$chatroom.removeAttr('style');
		$('#messages', $chatroom).removeAttr('style');
		$write.removeAttr('style');
		$online.removeAttr('style');
	}
	
	function start_resp() {
		var _w = jQuery(window).width();
		if ( _w > 800 ) {
			resetAutoHeight();
			autoHeight();
		} else {
			resetAutoHeight();
		}
	}
	
	$(window).resize(function() {
		start_resp();	
	});
	
	

	start_resp();
	
	
	/*
	
		.content .aside    { width: 56%; padding-right:4%; }
		.content .chatroom { width: 36%; padding:0 0 0 4%; }
	
	*/
	
	// player audio
	$( '#player' ).audioPlayer({
	   classPrefix: 'audioplayer',
	   strPlay: 'Play',
	   strPause: 'Pause',
	   strVolume: 'Volume'
	});
	
});

