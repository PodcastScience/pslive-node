/*
 * Script
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
		$('.sharypic > iframe').css('height', h_sharypic);
	
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
	
	
});

