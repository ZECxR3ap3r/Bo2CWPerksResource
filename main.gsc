#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_net;

// Made By ZECxR3ap3r

main() {
	replacefunc(::give_perk, ::give_perk_cwz);
}

init() {
	precacheshader("specialty_chugabud_zombies");
	precacheshader("specialty_electric_cherry_zombie");
	precacheShader("specialty_vulture_zombies");
	precacheshader("minimap_icon_chugabud");
	precacheshader("minimap_icon_electric_cherry");
    	level thread onPlayerConnect();
}

onPlayerConnect() {
	level endon("end_game");
    	for(;;){
       		level waittill("connected", player);
        	player thread onPlayerSpawned();
    	}
}

onPlayerSpawned() {
    	self endon("disconnect");
	level endon("end_game");
    	for(;;) {
        	self waittill("spawned_player");
		if(!isdefined(self.initial_spawn)) {
			self.initial_spawn = 1;
			self thread PlayerDownedWatcher();
		}
    	}
}

give_perk_cwz( perk, bought ) {
	self SetPerk( perk );
	self.num_perks++;
	if ( is_true( bought ) ) {
		self maps\mp\zombies\_zm_audio::playerExert( "burp" );
		self delay_thread (1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );
		self setblur( 4, 0.1 );
		wait 0.1;
		self setblur(0, 0.1);
		self notify( "perk_bought", perk );
	}
	if(perk == "specialty_armorvest") {
		self.preMaxHealth = self.maxhealth;
		self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health"] );
	}
	if ( perk == "specialty_scavenger" ) {
		self.HasPerkSpecialtyTombstone = true;
	}
	if ( perk == "specialty_grenadepulldeath" ) {
        	self thread maps/mp/zombies/_zm_perk_electric_cherry::electric_cherry_reload_attack();
    	}
    	if ( perk == "specialty_finalstand" ) {
        	self.lives = 1;
        	self.hasperkspecialtychugabud = 1;
        	self notify( "perk_chugabud_activated" );
    	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_give ) ) {
		self thread [[ level._custom_perks[ perk ].player_thread_give ]]();
	}
	maps/mp/_demo::bookmark( "zm_player_perk", getTime(), self );
	self maps/mp/zombies/_zm_stats::increment_client_stat( "perks_drank" );
	self maps/mp/zombies/_zm_stats::increment_client_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( "perks_drank" );
	players = GET_PLAYERS();
	if ( use_solo_revive() && perk == "specialty_quickrevive" ) {
		self.lives = 1;
		level.solo_lives_given++;
		if( level.solo_lives_given >= 3 ) {
			flag_set( "solo_revive" );
		}
		self thread solo_revive_buy_trigger_move( perk );
	}
	maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
	if(!isDefined(self.perk_history)) {
		self.perk_history = [];
	}
	self.perk_history = add_to_array(self.perk_history,perk,false);
	self notify("perk_acquired");	
	self perk_hud_create( perk );
	self thread perk_think( perk );
}

perk_hud_create( perk ) {
    if ( !IsDefined( self.perk_hud ) ) {
        self.perk_hud = [];
    }
    switch( perk ) {
    	case "specialty_armorvest":
        	shader = "specialty_juggernaut_zombies";
        	break;
    	case "specialty_quickrevive":
        	shader = "specialty_quickrevive_zombies";
        	break;
    	case "specialty_fastreload":
        	shader = "specialty_fastreload_zombies";
        	break;
    	case "specialty_rof":
        	shader = "specialty_doubletap_zombies";
        	break;  
    	case "specialty_longersprint":
        	shader = "specialty_marathon_zombies";
        	break; 
    	case "specialty_flakjacket":
        	shader = "specialty_divetonuke_zombies";
        	break;  
    	case "specialty_deadshot":
        	shader = "specialty_ads_zombies";
        	break;
    	case "specialty_additionalprimaryweapon":
        	shader = "specialty_additionalprimaryweapon_zombies";
        	break; 
		case "specialty_scavenger": 
			shader = "specialty_tombstone_zombies";
        	break; 
    	case "specialty_finalstand":
			shader = "specialty_chugabud_zombies";
        	break; 
    	case "specialty_nomotionsensor":
			shader = "specialty_vulture_zombies";
        	break; 
    	case "specialty_grenadepulldeath":
			shader = "specialty_electric_cherry_zombie";
        	break; 
    	default:
        	shader = "";
        	break;
    }
    hud = newclienthudelem( self );
    hud.foreground = true;
    hud.sort = 1;
    hud.hidewheninmenu = true;
    hud.alignX = "center";
    hud.alignY = "bottom";
    hud.horzAlign = "user_center";
    hud.vertAlign = "user_bottom";
    hud.x = self.perk_hud.size * 17.5;
    hud.y = hud.y - 40;
    hud.alpha = 1;
    hud SetShader( shader, 24, 24 );
    
    self.perk_hud[ perk ] = hud;
    foreach(hud in self.perk_hud) {// Move Perks
    	hud.x -= 9;
    }
}

PlayerDownedWatcher() {
	level endon("end_game");
	while(1) {
		self waittill("player_downed");
		foreach(hud in self.perk_hud) {
    			self.perk_hud = [];
    			hud destroy();
    		}
		self notify( "stop_electric_cherry_reload_attack" );
	}
}
