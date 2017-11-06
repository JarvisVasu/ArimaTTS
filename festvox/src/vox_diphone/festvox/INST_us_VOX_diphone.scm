;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                       ;;
;;;                            [SOMEBODY]                                 ;;
;;;                         Copyright (c) 2000                            ;;
;;;                        All Rights Reserved.                           ;;
;;;                                                                       ;;
;;;  Distribution policy                                                  ;;
;;;     [CHOOSE ONE OF]                                                   ;;
;;;     Free for any use                                                  ;;
;;;     Free for non commercial use                                       ;;
;;;     something else                                                    ;;
;;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  An example diphone voice
;;;
;;;  Authors: [The people who did the work]
;;;

;;; Try to find out where we are
(if (assoc 'INST_us_VOX_diphone voice-locations)
    (defvar INST_us_VOX_dir 
      (cdr (assoc 'INST_us_VOX_diphone voice-locations)))
    ;;; Not installed in Festival yet so assume running in place
    (defvar INST_us_VOX_dir (pwd)))

(if (not (probe_file (path-append INST_us_VOX_dir "festvox/")))
    (begin
     (format stderr "INST_us_VOX: Can't find voice scm files they are not in\n")
     (format stderr "   %s\n" (path-append INST_us_VOX_dir "festvox/"))
     (format stderr "   Either the voice isn't linked into Festival\n")
     (format stderr "   or you are starting festival in the wrong directory\n")
     (error)))

;;;  Add the directory contains general voice stuff to load-path
(set! load-path (cons (path-append INST_us_VOX_dir "festvox/") load-path))

;;; other files we need
(require 'radio_phones)
(setup_cmu_lex) 
(require 'pos)
(require 'phrase)
(require 'tobi)
(require 'f2bf0lr)

;;; Speaker specific prosody parameters
(require 'INST_us_VOX_int)
(require 'INST_us_VOX_dur)

;;;  Ensure we have a festival with the right diphone support compiled in
(require_module 'UniSyn)

(set! INST_us_VOX_lpc_sep 
      (list
       '(name "INST_us_VOX_lpc_sep")
       (list 'index_file (path-append INST_us_VOX_dir "dic/VOXdiph.est"))
       '(grouped "false")
       (list 'coef_dir (path-append INST_us_VOX_dir "lpc"))
       (list 'sig_dir  (path-append INST_us_VOX_dir "lpc"))
       '(coef_ext ".lpc")
       '(sig_ext ".res")
       (list 'default_diphone 
	     (string-append
	      (car (cadr (car (PhoneSet.description '(silences)))))
	      "-"
	      (car (cadr (car (PhoneSet.description '(silences)))))))))

(set! INST_us_VOX_lpc_group 
      (list
       '(name "VOX_lpc_group")
       (list 'index_file 
	     (path-append INST_us_VOX_dir "group/VOXlpc.group"))
       '(grouped "true")
       (list 'default_diphone 
	     (string-append
	      (car (cadr (car (PhoneSet.description '(silences)))))
	      "-"
	      (car (cadr (car (PhoneSet.description '(silences)))))))))

;; Go ahead and set up the diphone db
(set! INST_us_VOX_db_name (us_diphone_init INST_us_VOX_lpc_sep))
;; Once you've built the group file you can comment out the above and
;; uncomment the following.
;(set! INST_us_VOX_db_name (us_diphone_init INST_us_VOX_lpc_group))

(define (INST_us_VOX_diphone_fix utt)
"(INST_us_VOX_diphone_fix UTT)
Map phones to phonological variants if the diphone database supports
them."
  (mapcar
   (lambda (s)
     (let ((name (item.name s)))
       (INST_us_VOX_diphone_fix_phone_name utt s)
       ))
   (utt.relation.items utt 'Segment))
  utt)

(define (INST_us_VOX_diphone_fix_phone_name utt seg)
"(INST_us_VOX_fix_phone_name UTT SEG)
Add the feature diphone_phone_name to given segment with the appropriate
name for constructing a diphone.  Basically adds _ if either side is part
of the same consonant cluster, adds $ either side if in different
syllable for preceding/succeeding vowel syllable."
  (let ((name (item.name seg)))
    (cond
     ((string-equal name "pau") t)
     ((string-equal "-" (item.feat seg 'ph_vc))
      (if (and (member_string name '(r w y l))
	       (member_string (item.feat seg "p.name") '(p t k b d g))
	       (item.relation.prev seg "SylStructure"))
	  (item.set_feat seg "us_diphone_right" (format nil "_%s" name)))
      (if (and (member_string name '(w y l m n p t k))
	       (string-equal (item.feat seg "p.name") 's)
	       (item.relation.prev seg "SylStructure"))
	  (item.set_feat seg "us_diphone_right" (format nil "_%s" name)))
      (if (and (string-equal name 's)
	       (member_string (item.feat seg "n.name") '(w y l m n p t k))
	       (item.relation.next seg "SylStructure"))
	  (item.set_feat seg "us_diphone_left" (format nil "%s_" name)))
      (if (and (string-equal name 'hh)
	       (string-equal (item.feat seg "n.name") 'y))
	  (item.set_feat seg "us_diphone_left" (format nil "%s_" name)))
      (if (and (string-equal name 'y)
	       (string-equal (item.feat seg "p.name") 'hh))
	  (item.set_feat seg "us_diphone_right" (format nil "_%s" name)))
      (if (and (member_string name '(p t k b d g))
	       (member_string (item.feat seg "n.name") '(r w y l))
	       (item.relation.next seg "SylStructure"))
	  (item.set_feat seg "us_diphone_left" (format nil "%s_" name)))
      )
     ((string-equal "ah" (item.name seg))
      (item.set_feat seg "us_diphone" "aa"))

   )))

(define (INST_us_VOX_voice_reset)
  "(INST_us_VOX_voice_reset)
Reset global variables back to previous voice."
  ;; whatever
)

;;;  Full voice definition 
(define (voice_INST_us_VOX_diphone)
"(voice_INST_us_VOX_diphone)
Set speaker to VOX in us from INST."
  (voice_reset)
  (Parameter.set 'Language 'americanenglish)
  ;; Phone set
  (Parameter.set 'PhoneSet 'radio)
  (PhoneSet.select 'radio)

  ;; token expansion
  (set! token_to_words english_token_to_words)

  ;; POS tagger
  (set! pos_lex_name "english_poslex")
  (set! pos_ngram_name 'english_pos_ngram)
  (set! pos_supported t)
  (set! guess_pos english_guess_pos)   ;; need this for accents
  ;; Lexicon selection
  (lex.select "cmu")
  (set! postlex_rules_hooks (list postlex_apos_s_check))
  ;; Phrase prediction
  (Parameter.set 'Phrase_Method 'prob_models)
  (set! phr_break_params english_phr_break_params)
  ;; Accent and tone prediction
  (set! int_tone_cart_tree f2b_int_tone_cart_tree)
  (set! int_accent_cart_tree f2b_int_accent_cart_tree)
  (Parameter.set 'Int_Method Intonation_Tree)

  (set! postlex_vowel_reduce_cart_tree 
	postlex_vowel_reduce_cart_data)
  ;; F0 prediction
  (set! f0_lr_start f2b_f0_lr_start)
  (set! f0_lr_mid f2b_f0_lr_mid)
  (set! f0_lr_end f2b_f0_lr_end)
  (set! int_lr_params INST_us_VOX_int_lr_params)
  (Parameter.set 'Int_Target_Method Int_Targets_LR)
  ;; Duration prediction
  (set! duration_cart_tree INST_us_VOX::zdur_tree)
  (set! duration_ph_info INST_us_VOX::phone_durs)
  (Parameter.set 'Duration_Method 'Tree_ZScores)
  (Parameter.set 'Duration_Stretch 1.1)

  ;; Waveform synthesizer: diphones
  (set! UniSyn_module_hooks (list INST_us_VOX_diphone_fix))
  (set! us_abs_offset 0.0)
  (set! window_factor 1.0)
  (set! us_rel_offset 0.0)
  (set! us_gain 0.9)

  (Parameter.set 'Synth_Method 'UniSyn)
  (Parameter.set 'us_sigpr 'lpc)
  (us_db_select INST_us_VOX_db_name)

  ;; set callback to restore some original values changed by this voice
  (set! current_voice_reset INST_us_VOX_voice_reset)

  (set! current-voice 'INST_us_VOX_diphone)
)

(proclaim_voice
 'INST_us_VOX_diphone
 '((language english)
   (gender COMMENT)
   (dialect american)
   (description
    "COMMENT"
    )
   (builtwith festvox-1.2)))

(provide 'INST_us_VOX_diphone)
