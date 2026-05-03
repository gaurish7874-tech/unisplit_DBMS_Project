import streamlit as st
import db
# the frontend dashboard, minimally stylised for a neat overview

st.set_page_config(
    page_title="Unisplit",
    page_icon=None,
    layout="wide",
    initial_sidebar_state="expanded"
)

# minimal styling in css
st.markdown("""
    <style>
        .main { background-color: #0f1117; }
        h1 { font-size: 2rem; font-weight: 700; color: #ffffff; letter-spacing: -0.5px; }
        h2 { font-size: 1.2rem; font-weight: 600; color: #c9d1d9; }
        .subtitle { color: #8b949e; font-size: 0.9rem; margin-top: -15px; margin-bottom: 30px; }
        .metric-card {
            background-color: #161b22;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 20px;
            margin: 5px 0;
        }
        .metric-value { font-size: 1.8rem; font-weight: 700; color: #ffffff; }
        .metric-label { font-size: 0.8rem; color: #8b949e; text-transform: uppercase; letter-spacing: 1px; }
        .positive { color: #3fb950; }
        .negative { color: #f85149; }
        [data-testid="stSidebar"] { background-color: #161b22; border-right: 1px solid #30363d; }
        .stDataFrame { border: 1px solid #30363d; border-radius: 8px; }
        div[data-testid="metric-container"] {
            background-color: #161b22;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 15px;
        }
    </style>
""", unsafe_allow_html=True)

# Title
st.markdown("<h1>Unisplit</h1>", unsafe_allow_html=True)
st.markdown('<p class="subtitle">Group Expense & Micro-Credit Management System</p>', unsafe_allow_html=True)

# sidebar w/ contents
with st.sidebar:
    st.markdown("### Navigation")
    page = st.selectbox("Select a page", [
        "Group Summary",
        "Net Balances",
        "Active Loans",
        "Users"
    ], label_visibility="collapsed")
    
    st.markdown("---")
    st.markdown("##### UCS310 — DBMS Project")
    st.markdown('<p style="color:#8b949e; font-size:0.8rem;">B.Tech 2nd Year<br>Dept. of CSE</p>', unsafe_allow_html=True)

# Pages
if page == "Group Summary":
    st.markdown("## Group Summary")
    df = db.get_groups()
    if not df.empty:
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Total Groups", len(df))
        with col2:
            st.metric("Total Expenses", int(df['total_expenses'].sum()))
        with col3:
            st.metric("Total Spent", f"Rs {df['total_spent'].sum():,.0f}")
        st.markdown("---")
        st.dataframe(df, width='stretch', hide_index=True)
    else:
        st.error("Could not load data")

elif page == "Net Balances":
    st.markdown("## Net Balances")
    df = db.get_balances()
    if not df.empty:
        st.markdown("---")
        def color_balance(val):
            if isinstance(val, (int, float)):
                return 'color: #3fb950' if val > 0 else 'color: #f85149'
            return ''
        styled = df.style.map(color_balance, subset=['net_balance'])
        st.dataframe(styled, width='stretch', hide_index=True)
    else:
        st.error("Could not load data")

elif page == "Active Loans":
    st.markdown("## Loans")
    df = db.get_loans()
    if not df.empty:
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Total Loans", len(df))
        with col2:
            overdue_count = len(df[df['status'] == 'overdue'])
            st.metric("Overdue", overdue_count)
        with col3:
            total_penalty = df['penalty_amount'].sum()
            st.metric("Total Penalties", f"Rs {total_penalty:,.0f}")
        st.markdown("---")
        st.dataframe(df, width='stretch', hide_index=True)
    else:
        st.error("Could not load data")

elif page == "Users":
    st.markdown("## Users")
    df = db.get_users()
    if not df.empty:
        st.metric("Registered Users", len(df))
        st.markdown("---")
        st.dataframe(df, width='stretch', hide_index=True)
    else:
        st.error("Could not load data")
