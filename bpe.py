from seq2seq.data.dictionary import Dictionary
from collections import Counter
from collections import defaultdict
import re

class BPE():
    def __init__(self, merges=2000):
        self.merges = merges
        self.bpe_vocabulary = Dictionary()
        self.eow = '</w>'
        self.space_words = []

    def update_spacewords(self, char1, char2):
        # update space_words
        for index, word in enumerate(self.space_words):
            for number, char in enumerate(word):
                if number < len(word):
                    if word[number] == char1 and word[number+1] == char2:
                        word[number:number + 2] = [''.join(word[number:number + 2])]
            self.space_words[index] = word

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
                self.bpe_vocabulary.add_word(word[y], count)
                pairs[word[y], word[y+1]] += count
            self.bpe_vocabulary.add_word(word[-1], count)

        # merge pairs
        for a in range(self.merges):
            # look for highest frequency
            print(max(pairs, key=pairs.get))
            char1, char2 = max(pairs, key=pairs.get)
            print(char1, char2)
            new_pair = char1 + char2
            new_count = pairs[char1, char2]
            print(new_pair)
            #add new pair to vocabulary
            self.bpe_vocabulary.add_word(new_pair, new_count)
            #update vocabulary
            char1_count = self.bpe_vocabulary.counts[self.bpe_vocabulary.word2idx[char1]]
            char2_count = self.bpe_vocabulary.counts[self.bpe_vocabulary.word2idx[char2]]

            self.bpe_vocabulary.counts[self.bpe_vocabulary.word2idx[char1]] = char1_count - new_count
            self.bpe_vocabulary.counts[self.bpe_vocabulary.word2idx[char2]] = char2_count - new_count

            self.update_spacewords(char1, char2)

            #update pairs
            pairs = defaultdict(int)
            for u in range(len(self.space_words)):
                word = self.space_words[u]
                count = counts[u]
                for j in range(len(word) - 1):
                    pairs[word[j], word[j + 1]] += count

        return self.bpe_vocabulary


    def apply_bpe_to_file(self, input_file):
        '''return file with applied bpe segmanetation with eow tag and whitespace between bp
        return: preprocessed/train.en -> preprocessed/bpe1_train.en
                preprocessed/bpe1_train.en -> preprocessed/bpe2_train.en
        '''

        with open(input_file, 'r') as f:
            data = f.readlines()

        output_file = 'bpe_' + input_file

        with open(output_file, 'w') as o:
            for line in data:
                line = self.bpe_segmentation(line, self.bpe_vocabulary)
                o.write(line)


    def bpe_segmentation(self, sent: str) -> str:
        sorted_pbe_voc = sorted(self.bpe_vocabulary.words, key=len)

        def split_with_bpe_dict(word: str):
            if len(word) <= 1:
                return word
            
            for pair in reversed(sorted_pbe_voc):
                if pair in word:
                    word_replaced = re.sub(pair, '<'+pair+'>', word)
                    left, right = word_replaced.split('<'+pair+'>')
                    encoded_left = split_with_bpe_dict(left)
                    encoded_right = split_with_bpe_dict(right)
                    return [encoded_left, pair, encoded_right]
                
            
        result_sent = []  
        for word in sent.split(' '):
            word = word + '</w>'
            word_bpe = ' '.join(list(self.flatten(split_with_bpe_dict(word))))
            result_sent.append(word_bpe)
            
        result_sent = ' '.join(result_sent)
        result_sent = re.sub(' +', ' ', result_sent).strip()
        
        return result_sent
        

        # remove several and trailing whitespaces (beginning and end)
    @classmethod
    def flatten(cls, L):
        for l in L:
            if isinstance(l, list):
                yield from cls.flatten(l)
            else:
                yield l

    def dropout(self, probability=0.5):
        pass




if __name__ == '__main__':
    src_dict = Dictionary.load('data/en-fr/prepared/dict.fr')
    tgt_dict = Dictionary.load('data/en-fr/prepared/dict.en')
    
    myBPE = BPE()
    myBPE.create_vocabulary(src_dict)
    myBPE.bpe_segmentation('je n&apos; ai jamais imaginé un seul instant que je serais désigné pour une fouille au corps complète .')