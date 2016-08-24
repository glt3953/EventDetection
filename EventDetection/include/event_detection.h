#ifndef EVENT_DETECTION_H_
#define EVENT_DETECTION_H_

namespace dsb {

class EventDetection {
public:
    EventDetection();
    ~EventDetection();
//    int Init();
    int Init(const char *source_path);
    int Detect(const char *audio_file);
    int Detect(const char *audio, int size);

private:
    int pack_duration_; // seconds
    int left_context_;
    int right_context_;
    int max_frame_size_;
    int sample_rate_;
    int out_state_dim_;
    int pos_label_idx_;
    char *model_file_;
    char *feat_conf_;
    char *ed_conf_;
	
	int avg_window_;
	float threshold_;

    float *score_buff_;
    void *asr_md_;
    void *asr_nn_;
};

}

#endif
