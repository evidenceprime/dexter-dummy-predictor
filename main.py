import spacy
import re
import pandas as pd

from typing import List, Optional
from fastapi import FastAPI, status
from pydantic import BaseModel
from collections import defaultdict
from itertools import groupby
from nltk import PorterStemmer


class Section(BaseModel):
    name: str
    start: int
    end: int


class Mention(BaseModel):
    id: int
    tag: Optional[str]
    offsets: List[int]
    words: List[str]


class Item(BaseModel):
    ids: List[int]
    text: str


class Equivalence(BaseModel):
    id: int
    items: List[Item]


class PredictorRequest(BaseModel):
    sections: List[Section]
    text: str


class PredictorResponse(BaseModel):
    mentions: List[Mention]
    equivalences: List[Equivalence]


app = FastAPI()
nlp = spacy.load("en_core_web_sm")
stemmer = PorterStemmer()


@app.get("/")
async def root():
    return {"detail": "A simple dummy NER model."}


@app.get("/entities", response_model=List[str], status_code=status.HTTP_200_OK)
async def entities():
    return nlp.get_pipe("ner").labels


@app.post("/predict", response_model=PredictorResponse, status_code=status.HTTP_200_OK)
async def predict(request: PredictorRequest):
    mentions = []

    # In case we use IO label encoding we could merge only same adjacent entities
    tokens = nlp(request.text)
    tokens_grouped = groupby(tokens, key=lambda token: token.ent_type_)
    for i, (ent, ent_group) in enumerate(tokens_grouped):
        group_values = [(elem.text, elem.lemma_, elem.idx) for elem in ent_group]
        words, lemmas, offsets = zip(*group_values)

        lemma_stem_text = " ".join([stemmer.stem(lemma) for lemma in lemmas])
        lemma_stem_text = re.sub(" +", " ", lemma_stem_text).strip()
        mentions.append(
            {
                "id": i,
                "tag": ent if ent else None,
                "offsets": offsets,
                "words": words,
                "text": " ".join(words),
                "lemma_stem_text": lemma_stem_text,
            }
        )

    # Group mentions into equivalence groups
    df = pd.DataFrame(mentions)
    df = df.query("tag.notna()")  # Take only relevant tags

    # First level of aggregation refers to almost the entity with text noise
    # E.g. "mice", "mice.", "Mice" => "mice"
    df = (
        df.groupby(["tag", "lemma_stem_text", "text"], as_index=False)
        .agg({"id": list})
        .rename(columns={"id": "ids"})
    )

    df["item"] = df[["text", "ids"]].to_dict('records')

    # Second level of aggregation refers to same entity, but expressed as plural form
    # E.g. "mouse", "mice" => "mice"
    df = (
        df.groupby(["tag", "lemma_stem_text"], as_index=False)
        .agg({"item": list})
        .rename(columns={"item": "items"})
    )

    df["id"] = range(len(df))
    equivalences = df[['id', 'items']].to_dict('records')

    return {"mentions": mentions, "equivalences": equivalences}
