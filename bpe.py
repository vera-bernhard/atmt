from seq2seq.data.dictionary import Dictionary
from collections import Counter
from collections import defaultdict

class BPE():
    def __init__(self, merges=2000):
        self.merges = merges
        self.vocabulary = Dictionary()
        self.eow = '</w>'
        self.space_words = []

    def create_vocabulary(self, vocabulary: Dictionary):
        '''create bpe-vocabulary from existing word-vocabulary
        '''
        words = vocabulary.words
        space_words = []
        counts = vocabulary.counts
        pairs = defaultdict(int)

        # separate all characters, add eow tag
        for word in words:
            temp = ''
            for e in range(len(word)-1):
                char = word[e]
                temp = temp + char + ' '
            temp = temp + word[-1] + self.eow
            space_words.append(temp.split())
        self.space_words = space_words

        for i in range(len(self.space_words)):
            word = self.space_words[i]
            count = counts[i]
            # add each single character to vocabulary with count
            # create pair-dictionary with frequencies
            for y in range(len(word)-1):
                self.vocabulary.add_word(word[y], count)
                pairs[word[y], word[y+1]] += count
            self.vocabulary.add_word(word[-1], count)

        # merge pairs
        for a in range(self.merges):
            # look for highest frequency
            char1, char2 = max(pairs, key=pairs.get)
            print(char1, char2)
            new_pair = char1 + char2
            new_count = pairs[char1, char2]
            print(new_count)
            #add new pair to vocabulary
            self.vocabulary.add_word(new_pair, new_count)
            #update vocabulary
            char1_idx = self.vocabulary.word2idx[char1]
            char1_count = self.vocabulary.counts[char1_idx]
            char2_idx = self.vocabulary.word2idx[char2]
            char2_count = self.vocabulary.counts[char2_idx]

            self.vocabulary.counts[char1_idx] = char1_count - new_count
            self.vocabulary.counts[char2_idx] = char2_count - new_count

            #update space_words
            space_words = []
            for word in self.space_words:
                o = -1
                now_test=''
                for char in word:
                    o += 1
                    prev_test = now_test
                    now_test = word[o]

                    if prev_test == char1 and now_test == char2:
                        word[o:o+2] = [''.join(word[o:o+2])]
                space_words.append(word)
            self.space_words = space_words

            #update pairs
            pairs = defaultdict(int)
            for u in range(len(self.space_words)):
                word = self.space_words[u]
                count = counts[u]
                for j in range(len(word) - 1):
                    pairs[word[j], word[j + 1]] += count

        return self.vocabulary

    def make_eow_tag(self, word):
        pass

    def apply_bpe_to_file(self, file, vocabulary):
        '''return file with applied bpe segmanetation with eow tag and whitespace between bp
        return: preprocessed/train.en -> preprocessed/bpe1_train.en
                preprocessed/bpe1_train.en -> preprocessed/bpe2_train.en
        '''
        pass

    def bpe_segmentation(self, string, vocab):
        pass

    def dropout(self, probability=0.5):
        pass

