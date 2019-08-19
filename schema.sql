/* Version 3.0 of the Voy database.
    - See Cody Peraklis (team@thevoyapp.com) for questions
    - Created 2019-08-14
*/

----------------------------- ENTITIES -----------------------------------------
/*  Basic user profile
    - Other information maintained in Cognito
*/
CREATE TABLE user (
  id        UUID          PRIMARY KEY,      -- Generated by Cognito
  username  TEXT          NOT NULL UNIQUE,  -- Associated with Cognito
  subpath   TEXT          NOT NULL UNIQUE,  -- Access. From Cognito log in
  created   TIMESTAMPTZ   NOT NULL,
  updated   TIMESTAMPTZ   NOT NULL,
  private   BOOLEAN,                        -- Private vs Public account
  name      TEXT,
  bio       TEXT,
  photo_url TEXT,
  audio_url TEXT,
  video_url TEXT,
  data      JSONB
);

/* A single instance of a story.
    - Location in separate table
*/
CREATE TABLE tour (
  id          UUID        PRIMARY KEY,
  owner       UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  title       TEXT,
  description TEXT,
  photo_url   TEXT        NOT NULL,
  audio_url   TEXT        NOT NULL,
  video_url   TEXT,
  data        JSONB,
  updated     TIMESTAMPTZ NOT NULL,
  private     BOOLEAN,
  access_code TEXT
);

/* Sub-unit of a tour. */
CREATE TABLE checkpoint (
  tour        UUID                    NOT NULL REFERENCES tour(id) ON DELETE CASCADE,
  subid       UUID                    NOT NULL,
  start_rel   REAL                    NOT NULL,
  photo_url   TEXT,
  region      GEOGRAPHY(POLYGON,4326),
  data        JSONB,
  interrupt   BOOLEAN,
  PRIMARY KEY (tour, subid)
);

/* Group of tours represented together */
CREATE TYPE collection_t as ENUM('scavenger', 'series', 'feed');
CREATE TABLE collection (
  id          UUID          PRIMARY KEY,
  owner       UUID          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  type        collection_t  NOT NULL,
  title       TEXT          NOT NULL,
  photo_url   TEXT,
  description TEXT,
  data        JSONB,
  ordered     BOOLEAN,
  private     BOOLEAN,
  access_code TEXT
);

/* Entity as part of promotion or time-based importance */
CREATE TABLE event (
  id                UUID        PRIMARY KEY,
  owner             UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  target_tour       UUID        REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID        REFERENCES collection(id) ON DELETE CASCADE,
  start_time        TIMESTAMPTZ, -- NULL = -infinity
  end_time          TIMESTAMPTZ, -- NULL = infinity
  name              TEXT,
  description       TEXT,
  photo_url         TEXT,
  audio_url         TEXT,
  video_url         TEXT,
  private           BOOLEAN,
  access_code       TEXT,
  leaderboard       BOOLEAN, -- Enabled or Disabled
  data              JSONB,
  CONSTRAINT  single_event_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_collection IS NULL THEN 1 ELSE 0 END
    ) = 1
  )
);

/* Event success reward */
CREATE TABLE trophy (
  id          UUID    PRIMARY KEY,
  event       UUID    NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  photo_url   TEXT    NOT NULL,
  name        TEXT,
  description TEXT,
  winnings    JSONB
);

/* Comment attached to another entity */
CREATE TABLE comment (
  id                UUID    PRIMARY KEY,
  user              UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  body              TEXT,
  special           JSONB,
  target_tour       UUID    REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID    REFERENCES collection(id) ON DELETE CASCADE,
  target_comment    UUID    REFERENCES comment(id) ON DELETE CASCADE,
  updated           TIMESTAMPTZ,
  CONSTRAINT single_comment_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 0 ELSE 1 END
    + CASE WHEN target_collection IS NULL THEN 0 ELSE 1 END
    + CASE WHEN target_comment IS NULL THEN 0 ELSE 1 END
    ) = 1
  )
);

/* Tag entity */
CREATE TABLE tag (
  name      TEXT    PRIMARY KEY,
  referent  UUID    NOT NULL
);

/* Messages between users */
CREATE TABLE message (
  id        UUID  PRIMARY KEY,
  sender    UUID NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  reciever  UUID NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  body      TEXT,
  special   JSONB,
  sent      TIMESTAMPTZ NOT NULL,
  deliverd  TIMESTAMPTZ,
  read      TIMESTAMPTZ
);

/* System-level awards */
CREATE TABLE achievement (
  id          UUID  PRIMARY KEY,
  name        TEXT  NOT NULL UNIQUE,
  image       TEXT  NOT NULL UNIQUE,
  description TEXT,
  photo_url   TEXT,
  audio_url   TEXT,
  video_url   TEXT,
  updated     TIMESTAMPTZ,
  winnings    JSONB,
  value       REAL
);

--------------------------------- HAS-A RELATIONSHIP ---------------------------

/* Tour as a member of a collection */
CREATE TABLE collection_tour (
  collection  UUID        NOT NULL REFERENCES collection(id) ON DELETE CASCADE,
  tour        UUID        NOT NULL REFERENCES tour(id) ON DELETE CASCADE,
  inserted    TIMESTAMPTZ NOT NULL,
  weight      SMALLINT,   -- For possible ordering
  data        JSONB,
  PRIMARY KEY (collection, tour)
);

/* Entry in a leaderboard */
CREATE TABLE leaderboard (
  event       UUID    NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  user        UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  start_time  TIMESTAMPTZ,
  end_time    TIMESTAMPTZ,
  score       REAL,
  PRIMARY KEY (event, user)
);

/* Tag associated with another entity */
CREATE TABLE tagging (
  id                UUID  PRIMARY KEY,
  tag               UUID  NOT NULL REFERENCES tag(referent) ON DELETE RESTRICT,
  tag_name          TEXT  NOT NULL REFERENCES tag(name) ON DELETE RESTRICT,
  target_tour       UUID  REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID  REFERENCES collection(id) ON DELETE CASCADE,
  target_event      UUID  REFERENCES event(id) ON DELETE CASCADE,
  CONSTRAINT single_tagging_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_collection IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_event IS NULL THEN 0 ELSE 1 END
    ) = 1
  )
);

/* Saved tours and associated collections or events */
CREATE TABLE saved (
  user        UUID          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  tour        UUID[],
  collection  UUID[],
  event       UUID[],
  updated     TIMESTAMPTZ   NOT NULL,
  PRIMARY KEY (user, tour)
);

/* Achievement won by user */
CREATE TABLE user_achievement (
  user        UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  achievement UUID    NOT NULL REFERENCES achievement(id) ON DELETE CASCADE,
  achieved    TIMESTAMPTZ
  PRIMARY KEY (user, achievement)
);

------------------------------- WATCHING RELATIONSHIP --------------------------

/* User watching a for updates */
CREATE TABLE follow (
  following_user        UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE ,
  subid                 UUID        NOT NULL,
  followed_user         UUID        REFERENCES user(id) ON DELETE CASCADE ,
  followed_tour         UUID        REFERENCES tour(id) ON DELETE CASCADE,
  followed_collection   UUID        REFERENCES collection(id) ON DELETE CASCADE,
  followed_event        UUID        REFERENCES event(id) ON DELETE CASCADE,
  followed              TIMESTAMPTZ NOT NULL,
  last_check            TIMESTAMPTZ NOT NULL,
  CONSTRAINT  single_follow_followed CHECK (
    ( CASE WHEN followed_user IS NULL THEN 1 ELSE 0 END +
      CASE WHEN followed_tour IS NULL THEN 1 ELSE 0 END +
      CASE WHEN followed_collection IS NULL THEN 1 ELSE 0 END +
      CASE WHEN followed_event IS NULL THEN 1 ELSE 0 END
    ) = 1
  ),
  PRIMARY KEY (following_user, subid)
);

------------------------------ INDICATES RELATIONSHIP --------------------------

/* Vote interaction */
CREATE TYPE vote_t AS ENUM('upvote','downvote');
CREATE TABLE vote (
  id                UUID        PRIMARY KEY,
  user              UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  value             vote_t,
  updated           TIMESTAMPTZ NOT NULL,
  target_tour       UUID        REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID        REFERENCES collection(id) ON DELETE CASCADE,
  target_comment    UUID        REFERENCES comment(id) ON DELETE CASCADE,
  target_event      UUID        REFERENCES event(id) ON DELETE CASCADE,
  CONSTRAINT single_vote_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_collection IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_event IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_comment IS NULL THEN 0 ELSE 1 END
    ) = 1
  )
);

/* Flag entity relationship */
CREATE TYPE flag_t as ENUM('inappropriate', 'irrelevant');
CREATE TABLE flag (
  id                UUID    PRIMARY KEY,
  user              UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  type              flag_t  NOT NULL,
  updated           TIMESTAMPTZ NOT NULL,
  target_tour       UUID    REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID    REFERENCES collection(id) ON DELETE CASCADE,
  target_comment    UUID    REFERENCES comment(id) ON DELETE CASCADE,
  target_event      UUID    REFERENCES event(id) ON DELETE CASCADE,
  target_user       UUID    REFERENCES user(id) ON DELETE CASCADE,
  CONSTRAINT single_flag_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_collection IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_comment IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_event IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_user IS NULL THEN 0 ELSE 1 END
    ) = 1
  )
);

-------------------------------- LOCATED RELATIONSHIP --------------------------

/* Table of locations */
CREATE TABLE location (
  id                 UUID                      PRIMARY KEY, -- different to allow possibility of multiple tours / location
  target_tour        UUID                      REFERENCES tour(id) ON DELETE CASCADE,
  target_event       UUID                      REFERENCES event(id) ON DELETE CASCADE,
  target_collection  UUID                      REFERENCES collection(id) ON DELETE CASCADE,
  data               JSONB,
  region             GEOGRAPHY(POLYGON,4326)   NOT NULL,
  CONSTRAINT single_location_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_collection IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_event IS NULL THEN 1 ELSE 0 END
    ) = 1
  )
);

------------------------------ SCORE RELATIONSHIP ------------------------------

/* Score [0.0,1.0] as a creator/creation */
CREATE TABLE rank (
  id                UUID PRIMARY KEY,
  score             REAL  NOT NULL DEFAULT 0.0,
  target_tour       UUID  REFERENCES tour(id) ON DELETE CASCADE,
  target_event      UUID REFERENCES event(id) ON DELETE CASCADE,
  target_collection UUID REFERENCES collection(id) ON DELETE CASCADE,
  target_comment    UUID REFERENCES comment(id) ON DELETE CASCADE,
  target_user       UUID REFERENCES user(id) ON DELETE CASCADE,
  CONSTRAINT single_rank_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_collection IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_event IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_comment IS NULL THEN 0 ELSE 1 END +
      CASE WHEN target_user IS NULL THEN 0 ELSE 1 END
    ) = 1
  )
);

/* Rank user as a user actions */
CREATE TYPE user_action AS ENUM('listen', 'vote', 'flag', 'engagement', 'following');
CREATE TABLE user_rank (
  user    UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  action  user_action NOT NULL,
  score   REAL NOT NULL DEFAULT 0.0,
  updated TIMESTAMPTZ,
  PRIMARY KEY(user, action)
);

----------------------------------- ACCESS RELATIONSHIP ------------------------

/* Grant access to private entites or revoke to public */
CREATE TYPE access_status AS ENUM('requested', 'invited', 'accepted', 'blocked');
CREATE TABLE access (
  user              UUID          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  subid             UUID          PRIMARY KEY,
  target_event      UUID          REFERENCES event(id) ON DELETE CASCADE,
  target_collection UUID          REFERENCES collection(id) ON DELETE CASCADE,
  target_tour       UUID          REFERENCES tour(id) ON DELETE CASCADE,
  target_user       UUID          REFERENCES user(id) ON DELETE CASCADE,
  updated           TIMESTAMPTZ   NOT NULL,
  status            access_status NOT NULL,
  history           UUID[],       -- access_history ids
  data              JSONB,
  CONSTRAINT  single_access_target CHECK (
    ( CASE WHEN target_user IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_tour IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_collection IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_event IS NULL THEN 1 ELSE 0 END
    ) = 1
  ),
  PRIMARY KEY (user, subid)
);

/* User blocking another user */
CREATE TABLE block (
  blocking_user   UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  blocked_user    UUID    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  blocked         TIMESTAMPTZ NOT NULL,
  reason          TEXT,
  PRIMARY KEY (blocking_user, blocked_user)
);

----------------------------------- ATTENDS RELATIONSHIP -----------------------

/* Event anticipation response */
CREATE TYPE attendance_t AS ENUM('invited', 'not going', 'interested', 'going', 'went');
CREATE TABLE attendance (
  event       UUID          NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  user        UUID          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  type        attendance_t  NOT NULL DEFAULT 'interested',
  updated     TIMESTAMPTZ   NOT NULL,
  PRIMARY KEY (event, user)
);

-------------------------------------- HISTORICAL ------------------------------

/* Record changes to user profile and settings. */
CREATE TABLE info_change (
  user        UUID          REFERENCES user(id) ON DELETE CASCADE,
  username    TEXT,
  subpath     TEXT,
  private     BOOLEAN,
  name        TEXT,
  bio         TEXT,
  photo_url   TEXT,
  audio_url   TEXT,
  video_url   TEXT,
  data        JSOB,
  occurence   TIMESTAMPTZ,
  PRIMARY KEY (user, occurence)
);

/* History of access */
CREATE TABLE access_history (
  id      UUID            PRIMARY KEY,
  status  access_status,
  data    JSONB,
  event   TIMESTAMPTZ     NOT NULL
);

/* History of attendance */
CREATE TABLE attendance_history (
  user        UUID          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  event       UUID          NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  type        attendance_t  NOT NULL DEFAULT 'interested',
  updated     TIMESTAMPTZ   NOT NULL,
  PRIMARY KEY (event, user, updated)
);

/* History of a comment */
CREATE TABLE comment_edits (
  id      UUID    PRIMARY KEY,
  comment UUID    NOT NULL REFERENCES comment(id) ON DELETE CASCADE,
  body    TEXT,
  special JSONB,
  updated TIMESTAMPTZ
);

/* Log of user location */
CREATE TABLE user_location (
  id          UUID                    PRIMARY KEY,
  user        UUID                    NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  location    GEOGRAPHY(POINT,4326)   NOT NULL,
  occurence   TIMESTAMPTZ             NOT NULL,
  event       UUID                    REFERENCES event(id) ON DELETE SET NULL,
  collection  UUID                    REFERENCES collection(id) ON DELETE SET NULL,
  tour        UUID                    REFERENCES tour(id) ON DELETE SET NULL,
  tourtime    REAL
);

/* Log user listens */
CREATE TYPE listen_t AS ENUM('standard', 'preview');
CREATE TABLE listen (
  id          UUID        PRIMARY KEY,
  user        UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  tour        UUID        NOT NULL REFERENCES tour(id) ON DELETE CASCADE,
  collection  UUID        REFERENCES collection(id) ON DELETE SET NULL,
  event       UUID        REFERENCES event(id) ON DELETE SET NULL,
  type        listen_t    NOT NULL DEFAULT 'standard',
  start_rel   REAL        NOT NULL,
  start_time  TIMESTAMPTZ NOT NULL,
  end_rel     REAL        NOT NULL,
  end_time    TIMESTAMPTZ NOT NULL
);

/* History of latest listens for users */
CREATE TABLE personal_history (
  user              UUID        NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  subid             UUID        NOT NULL,
  target_tour       UUID        REFERENCES tour(id) ON DELETE CASCADE,
  target_collection UUID        REFERENCES collection(id) ON DELETE CASCADE,
  target_event      UUID        REFERENCES event(id) ON DELETE CASCADE,
  progress          REAL,
  count             SMALLINT,
  first             TIMESTAMPTZ NOT NULL,
  last              TIMESTAMPTZ NOT NULL,
  complete          BOOLEAN,
  CONSTRAINT  single_history_target CHECK (
    ( CASE WHEN target_tour IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_collection IS NULL THEN 1 ELSE 0 END +
      CASE WHEN target_event IS NULL THEN 1 ELSE 0 END
    ) = 1
  ),
  CONSTRAINT  single_progress_type CHECK (
    ( CASE WHEN progress IS NULL THEN 1 ELSE 0 END +
      CASE WHEN count IS NULL THEN 1 ELSE 0 END
    ) = 1
  ),
  PRIMARY KEY (user, subid)
);