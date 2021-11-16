from seq2seq.data.dictionary import Dictionary
from collections import defaultdict
import re
import random
import pdb

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
            for index, char in enumerate(word):
                if index < len(word):
                    temp = temp + char + ' '
            temp = temp + word[-1] + self.eow
            space_words.append(temp.split())
        self.space_words = space_words

        for i, word in enumerate(self.space_words):
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
            char1, char2 = max(pairs, key=pairs.get)
            new_pair = char1 + char2
            new_count = pairs[char1, char2]
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
            for u, word in enumerate(self.space_words):
                count = counts[u]
                for j in range(len(word) - 1):
                    pairs[word[j], word[j + 1]] += count

        return self.bpe_vocabulary


    def apply_bpe_to_file(self, input_file, vocabulary):
        '''return file with applied bpe segmanetation with eow tag and whitespace between bp
        return: preprocessed/train.en -> preprocessed/bpe1_train.en
                preprocessed/bpe1_train.en -> preprocessed/bpe2_train.en
        '''

        print(input_file)
        with open(input_file, 'r') as f:
            data = f.readlines()
        output_file = input_file + '_bpe'

        with open(output_file, 'w') as o:
            for line in data:
                line = line.strip()
                line = self.bpe_segmentation(line, vocabulary)
                o.write(line)
                o.write('\n')

        return output_file


    def bpe_segmentation(self, sent: str, vocab: Dictionary) -> str:
        '''Encodes a sentence given a bpe dictionary'''
        sorted_pbe_voc = sorted(vocab.words, key=len)

        def split_with_bpe_dict(word: str):
            if len(word) <= 1:
                return word
            
            # look at longest byte pairs first
            for pair in reversed(sorted_pbe_voc):
                if word == pair:
                    return ['', word, '']
                elif pair in word:
                    try: 
                        word_replaced = re.sub(re.escape(pair), r'<'+pair+'>', word, count=1)
                    except ValueError:
                        pdb.set_trace()
                    left, right = word_replaced.split('<'+pair+'>')
                    encoded_left = split_with_bpe_dict(left)
                    encoded_right = split_with_bpe_dict(right)
                    return [encoded_left, pair, encoded_right]
                
            
        result_sent = []  
        for word in sent.split(' '):
            word = word + '</w>'
            word_bpe_list = [x for x in list(self.flatten(split_with_bpe_dict(word))) if x is not None]
            word_bpe = ' '.join(word_bpe_list)
            result_sent.append(word_bpe)
            
        result_sent = ' '.join(result_sent)
        result_sent = re.sub(' +', ' ', result_sent).strip()
        
        return result_sent

    def dropout(self, probability=0.5):
        vocab = self.bpe_vocabulary
        new_vocab = Dictionary()
        number_random_samples = int(len(vocab) * probability)

        random_list = random.sample(range(0, len(self.bpe_vocabulary)), number_random_samples)

        for element in random_list:
            word = self.bpe_vocabulary.words[element]
            count = self.bpe_vocabulary.counts[element]

            new_vocab.add_word(word, count)
        return new_vocab

        
    @classmethod
    def flatten(cls, L):
        for l in L:
            if isinstance(l, list):
                yield from cls.flatten(l)
            else:
                yield l


if __name__ == '__main__':
    src_dict = Dictionary.load('data/en-fr/prepared/dict.fr')
    tgt_dict = Dictionary.load('data/en-fr/prepared/dict.en')
    
    myBPE = BPE()
    myBPE.create_vocabulary(src_dict)
    myBPE.bpe_segmentation('durant la fin du XXe siècle , la Yougoslavie était considérée comme un État voyou par les États @-@ Unis .', myBPE.bpe_vocabulary)