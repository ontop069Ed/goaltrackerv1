from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///goals.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Goal(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    target_date = db.Column(db.Date, nullable=False)
    progress = db.Column(db.Integer, default=0)

    def __repr__(self):
        return f'<Goal {self.title}>'

with app.app_context():
    db.create_all()

@app.route('/api/goals', methods=['GET'])
def get_goals():
    goals = Goal.query.all()
    return jsonify([{'id': g.id, 'title': g.title, 'target_date': g.target_date.isoformat(), 'progress': g.progress} for g in goals])

@app.route('/api/goals', methods=['POST'])
def create_goal():
    data = request.json
    if not data or 'title' not in data or 'target_date' not in data:
        return jsonify({'error': 'Missing title or target_date'}), 400
    goal = Goal(title=data['title'], target_date=datetime.fromisoformat(data['target_date']).date())
    db.session.add(goal)
    db.session.commit()
    return jsonify({'id': goal.id}), 201

if __name__ == '__main__':
    app.run(debug=True)