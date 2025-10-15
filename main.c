#include <SDL3/SDL_video.h>
#define SDL_MAIN_USE_CALLBACKS 1  /* use the callbacks instead of main() */
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;

typedef struct {
	float y; 
} Paddle;

typedef struct {
	float x, y, vel_x, vel_y;
} Ball;

typedef struct {
	Paddle one;
	Paddle two;
	Ball ball;
	int score1, score2;
	bool newgame;
	int init_frames_remaining;

	bool left_touch_active;
	float left_touch_y;

	bool right_touch_active;
	float right_touch_y;
} AppState;

float clamp(float value, float min, float max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

float rand_float_range(float min, float max) {
    return min + ((float)rand() / (float)RAND_MAX) * (max - min);
}

int get_ball_region(float one_left_bound, float one_right_bound, float one_top_bound, float one_bottom_bound, float two_left_bound, float two_right_bound, float two_top_bound, float two_bottom_bound, float ball_radius, float ball_left_bound, float ball_right_bound, float ball_top_bound, float ball_bottom_bound, float logw, float logh) {
	// 1 above paddle one
	// 2 behind paddle one
	// 3 inside paddle one
	// 4 below paddle one
	// 5 in front of paddles
	// 6 above paddle two
	// 7 behind paddle two
	// 8 inside paddle two
	// 9 below paddle two
	// 10 left of screen
	// 11 right of screen
	// 12 top of screen
	// 13 bottom of screen
	
	if (ball_top_bound <= 0) {
		return 12;
	} else if (ball_bottom_bound >= logh) {
		return 13;
	} else if (ball_left_bound > one_right_bound && ball_right_bound < two_left_bound) {
		return 5;
	} else if (ball_left_bound <= one_right_bound) {
		if (ball_right_bound <= 0) {
			return 10;
		} else if (ball_bottom_bound < one_bottom_bound && ball_top_bound > one_top_bound) {
			if (ball_right_bound <= one_left_bound) {
				return 2;
			} else {
				return 3;
			}
		} else if (ball_bottom_bound <= one_top_bound) {
			return 1;
		} else if (ball_top_bound >= one_bottom_bound) {
			return 4;
		} else {
			return 3;
		}
	} else if (ball_right_bound >= two_left_bound) {
		if (ball_left_bound >= logw) {
			return 11;
		} else if (ball_bottom_bound < two_bottom_bound && ball_top_bound > two_top_bound) {
			if (ball_left_bound >= two_right_bound) {
				return 7;
			} else {
				return 8;
			}
		} else if (ball_bottom_bound <= two_top_bound) {
			return 6;
		} else if (ball_top_bound >= two_bottom_bound) {
			return 9;
		} else {
			return 8;
		}
	} else {
		return 5;
	}
}


float calc_new_y(float vel_y, float ball_y, float ball_radius, float paddle_y, float paddle_height) {
	float factor = 0.005;
	float hit_pos = (ball_y + ball_radius - paddle_y) / (paddle_height + ball_radius * 2);
	float dy = (hit_pos - 0.5) * factor;
	return vel_y + dy;
}

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]) {

	srand((unsigned int)time(NULL));

	AppState *state = SDL_calloc(1, sizeof(AppState));
	if (!state) {
		SDL_Log("Couldn't allocate app state");
		return SDL_APP_FAILURE;
	}

	state->newgame = true;
	state->init_frames_remaining = 10;

	*appstate = state;
	
    /* Create the window */
    if (!SDL_CreateWindowAndRenderer("Hello World", 800, 600, SDL_WINDOW_FULLSCREEN, &window, &renderer)) {
        SDL_Log("Couldn't create window and renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

/* This function runs when a new event (mouse input, keypresses, etc) occurs. */
SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{	
    AppState *state = (AppState *)appstate;

    switch (event->type) {
		case SDL_EVENT_QUIT:
			return SDL_APP_SUCCESS;
	
		case SDL_EVENT_FINGER_DOWN:
		case SDL_EVENT_FINGER_MOTION: {
			float x = event->tfinger.x;
			float y = event->tfinger.y;
	
			if (x < 0.5f) {
				state->left_touch_active = true;
				state->left_touch_y = y;
			} else {
				state->right_touch_active = true;
				state->right_touch_y = y;
			}
			break;
		}
	
		case SDL_EVENT_FINGER_UP: {
			float x = event->tfinger.x;
	
			if (x < 0.5f)
				state->left_touch_active = false;
			else
				state->right_touch_active = false;
			break;
		}
	
		case SDL_EVENT_KEY_DOWN:
			if (event->key.key == SDLK_ESCAPE)
				return SDL_APP_SUCCESS;
			break;
		}

	return SDL_APP_CONTINUE;
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate(void *appstate)
{
	AppState *state = (AppState *)appstate;
	
    int w = 0, h = 0;
    const float scale = 4.0f;
	float x_one, x_two = 0.0f;
	const float thickness = 10;
	const float height = 50;
	const float ball_diameter = 5;

    SDL_GetRenderOutputSize(renderer, &w, &h);
    SDL_SetRenderScale(renderer, scale, scale);

    float logicw = (float) w / scale;
	float logich = (float) h / scale;
	float gap = (logicw) * 0.1f;

	x_one = gap;
	x_two = ((float) w / scale) - gap - thickness;

	char score_string[24];
	snprintf(score_string, sizeof(score_string), "%d : %d", state->score1, state->score2);
	float text_x = (logicw - SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE * SDL_strlen(score_string)) / 2;
    float text_y = (logich - SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE) / 2;

	float one_left_bound = x_one;
	float one_right_bound = x_one + thickness;
	float one_top_bound = state->one.y;
	float one_bottom_bound = state->one.y + height;
	float two_left_bound = x_two;
	float two_right_bound = x_two + thickness;
	float two_top_bound = state->two.y;
	float two_bottom_bound = state->two.y + height;
	float ball_radius = ball_diameter / 2.0f;
	float ball_left_bound = state->ball.x - ball_radius;
	float ball_right_bound = state->ball.x + ball_radius;
	float ball_top_bound = state->ball.y - ball_radius;
	float ball_bottom_bound = state->ball.y + ball_radius;

	// 1 above paddle one
	// 2 behind paddle one
	// 3 inside paddle one
	// 4 below paddle one
	// 5 in front of paddles
	// 6 above paddle two
	// 7 behind paddle two
	// 8 inside paddle two
	// 9 below paddle two
	// 10 left of screen
	// 11 right of screen
	// 12 top of screen
	// 13 bottom of screen
	int past_ball_region = get_ball_region(one_left_bound, one_right_bound, one_top_bound, one_bottom_bound, two_left_bound, two_right_bound, two_top_bound, two_bottom_bound, ball_radius, ball_left_bound, ball_right_bound, ball_top_bound, ball_bottom_bound, logicw, logich); 

	const bool* keystate = SDL_GetKeyboardState(NULL);

	// --- Keyboard input (desktop) ---
	if (keystate[SDL_SCANCODE_W]) {
		state->one.y -= 0.01f;
	} else if (keystate[SDL_SCANCODE_S]) {
		state->one.y += 0.01f;
	}
	
	if (keystate[SDL_SCANCODE_UP]) {
		state->two.y -= 0.01f;
	} else if (keystate[SDL_SCANCODE_DOWN]) {
		state->two.y += 0.01f;
	}

	// Touch control (mobile)
    if (state->left_touch_active)
        state->one.y = state->left_touch_y * logich;

    if (state->right_touch_active)
        state->two.y = state->right_touch_y * logich;
	
	state->one.y = clamp(state->one.y, 0.0f, logich - height);
	state->two.y = clamp(state->two.y, 0.0f, logich - height);
	
	if (state->init_frames_remaining > 0) {
		state->init_frames_remaining--;
	} else if (state->newgame) {
		state->ball.x = logicw /  2.0f;
		state->ball.y = logich /  2.0f;
		state->ball.vel_x = rand_float_range(0.03f, 0.08f) * (rand_float_range(0.0f, 10.0f) > 0.05f ? 1.0f : -1.0f);
		state->ball.vel_y = rand_float_range(-0.0002f, 0.0006f);
		state->newgame = false;
	}

	state->ball.x += state->ball.vel_x;
	state->ball.y += state->ball.vel_y;

	one_left_bound = x_one;
	one_right_bound = x_one + thickness;
	one_top_bound = state->one.y;
	one_bottom_bound = state->one.y + height;
	two_left_bound = x_two;
	two_right_bound = x_two + thickness;
	two_top_bound = state->two.y;
	two_bottom_bound = state->two.y + height;
	ball_radius = ball_diameter / 2.0f;
	ball_left_bound = state->ball.x - ball_radius;
	ball_right_bound = state->ball.x + ball_radius;
	ball_top_bound = state->ball.y - ball_radius;
	ball_bottom_bound = state->ball.y + ball_radius;

	// 1 above paddle one
	// 2 behind paddle one
	// 3 inside paddle one
	// 4 below paddle one
	// 5 in front of paddles
	// 6 above paddle two
	// 7 behind paddle two
	// 8 inside paddle two
	// 9 below paddle two
	// 10 left of screen
	// 11 right of screen
	// 12 top of screen
	// 13 bottom of screen
	int present_ball_region = get_ball_region(one_left_bound, one_right_bound, one_top_bound, one_bottom_bound, two_left_bound, two_right_bound, two_top_bound, two_bottom_bound, ball_radius, ball_left_bound, ball_right_bound, ball_top_bound, ball_bottom_bound, logicw, logich); 

	if (present_ball_region == 10) {
		state->score2 += 1;
		state->newgame = true;	
	} else if (present_ball_region == 11) {
		state->score1 += 1;
		state->newgame = true;	
	} else if (present_ball_region == 12 || present_ball_region == 13) {
		state->ball.vel_y *= -1.0f;
	} else if ((past_ball_region == 2 || past_ball_region == 7 || past_ball_region == 5) && (present_ball_region == 3 || present_ball_region == 8)) {
		state->ball.vel_x *= -1.05f;
		float relevant_paddle_y = 0;
		if (present_ball_region == 3) {
			relevant_paddle_y = state->one.y;
		} else {
			relevant_paddle_y = state->two.y;
		}
		state->ball.vel_y = calc_new_y(state->ball.vel_y, state->ball.y, ball_radius, relevant_paddle_y, height);
	} else if ((past_ball_region == 1 || past_ball_region == 6) && (present_ball_region == 3 || present_ball_region == 8)) {
		if (state->ball.vel_y > 0) {
			state->ball.vel_y *= -1.0f;
		}
		float relevant_top_bound = 0;
		if (present_ball_region == 3) {
			relevant_top_bound = one_top_bound;
		} else {
			relevant_top_bound = two_top_bound;
		}
		float new_y = relevant_top_bound - ball_radius;
		float new_vel_y = state->ball.vel_y + (new_y - state->ball.y);
		state->ball.y = new_y;
		state->ball.vel_y = new_vel_y;
	} else if ((past_ball_region == 4 || past_ball_region == 9) && (present_ball_region == 3 || present_ball_region == 8)) {
		if (state->ball.vel_y < 0) {
			state->ball.vel_y *= -1.0f;
		}
		float relevant_bottom_bound = 0;
		if (present_ball_region == 3) {
			relevant_bottom_bound = one_bottom_bound;
		} else {
			relevant_bottom_bound = two_bottom_bound;
		}
		float new_y = relevant_bottom_bound + ball_radius;
		float new_vel_y = state->ball.vel_y + (new_y - state->ball.y);
		state->ball.y = new_y; 
		state->ball.vel_y = new_vel_y;
	}
	
	struct SDL_FRect rect1 = {
		x_one,
		state->one.y,
		thickness,
		height
	};
	
	struct SDL_FRect rect2 = {
		x_two,
		state->two.y,
		thickness,
		height
	};

	struct SDL_FRect ball = {
		state->ball.x - (ball_diameter / 2.0f),
		state->ball.y - (ball_diameter / 2.0f),
		ball_diameter,
		ball_diameter
	};

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
	SDL_RenderDebugText(renderer, text_x, text_y, score_string);
    SDL_RenderFillRect(renderer, &rect1);
    SDL_RenderFillRect(renderer, &rect2);
    SDL_RenderFillRect(renderer, &ball);
    SDL_RenderPresent(renderer);

    return SDL_APP_CONTINUE;
}

/* This function runs once at shutdown. */
void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
	SDL_free(appstate);
}

